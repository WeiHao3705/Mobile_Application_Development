import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';
import '../services/password_hasher.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  /// Profile columns only. The legacy `password` column is deliberately not
  /// part of this list; it is fetched separately, and only when needed.
  static const String _profileSelectFields =
      'user_id, username, full_name, email, height, current_weight, target_weight, is_admin, profile_photo, date_of_birth, gender';

  SupabaseClient get client => _client ?? Supabase.instance.client;

  /// Logs in with Supabase Auth first. Accounts that predate Supabase Auth
  /// fall back to the legacy password column and are then given an Auth
  /// identity. Throws [AuthException] if a session cannot be established.
  Future<LoginUser?> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    final response = await client
        .from('User')
        .select(_profileSelectFields)
        .eq('username', normalizedUsername)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final row = Map<String, dynamic>.from(response);
    final email = row['email']?.toString().trim() ?? '';

    // 1. Preferred path: Supabase Auth owns the password.
    if (email.isNotEmpty &&
        await _trySignIn(email: email, password: normalizedPassword)) {
      return LoginUser.fromMap(row);
    }

    // 2. Legacy path for accounts that only have a password in the User table.
    final hashedPassword = PasswordHasher.hash(normalizedPassword);
    final storedPassword = await _fetchLegacyPassword(row['user_id']);

    if (!_passwordMatches(
      storedPassword: storedPassword,
      plainTextPassword: normalizedPassword,
      hashedPassword: hashedPassword,
    )) {
      return null;
    }

    // Establish a Supabase Auth session so RLS-protected requests are allowed.
    await _establishAuthSession(email: email, password: normalizedPassword);

    if (storedPassword.isNotEmpty && storedPassword != hashedPassword) {
      await _upgradePasswordHash(
        userId: row['user_id'],
        hashedPassword: hashedPassword,
      );
    }

    return LoginUser.fromMap(row);
  }

  /// Returns true on success, false when Supabase Auth rejects the
  /// credentials. Other failures (for example no network) propagate.
  Future<bool> _trySignIn({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException {
      return false;
    }
  }

  /// Returns the legacy password value, or '' when there is none or the
  /// database does not allow reading it (the recommended setup hides the
  /// column, in which case only Supabase Auth logins can succeed).
  Future<String> _fetchLegacyPassword(dynamic userId) async {
    try {
      final response = await client
          .from('User')
          .select('password')
          .eq('user_id', userId)
          .maybeSingle();
      return response?['password']?.toString() ?? '';
    } on PostgrestException {
      return '';
    }
  }

  /// Signs in, creating the Auth identity first when the account has none.
  /// Throws [AuthException] when no session can be established.
  Future<void> _establishAuthSession({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) {
      throw AuthException(
        'This account has no email address, so it cannot be signed in securely. Please contact support.',
      );
    }

    try {
      await client.auth.signInWithPassword(email: email, password: password);
      return;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final canCreateIdentity = message.contains('invalid login credentials') ||
          message.contains('user not found') ||
          message.contains('invalid credentials');

      if (!canCreateIdentity) {
        // e.g. "Email not confirmed": tell the user instead of hiding it.
        rethrow;
      }
    }

    await ensureAuthIdentity(email: email, password: password);
    await client.auth.signInWithPassword(email: email, password: password);
  }

  bool _passwordMatches({
    required String storedPassword,
    required String plainTextPassword,
    required String hashedPassword,
  }) {
    return storedPassword == hashedPassword || storedPassword == plainTextPassword;
  }

  Future<void> _upgradePasswordHash({
    required dynamic userId,
    required String hashedPassword,
  }) async {
    try {
      await client
          .from('User')
          .update({'password': hashedPassword})
          .eq('user_id', userId);
    } catch (_) {
      // Keep login successful even if migration update is blocked by policy.
    }
  }

  Future<void> ensureAuthIdentity({
    required String email,
    required String password,
  }) async {
    try {
      await client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        emailRedirectTo: null,
      );
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('already registered')) {
        return;
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    // Only send reset email if the account exists in Supabase Auth
    // (which means they signed up through the app)
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  Future<void> completePasswordReset({
    required String newPassword,
    String? email,
  }) async {
    final resolvedEmail = _normalizeEmail(
      email ?? client.auth.currentUser?.email ?? '',
    );
    if (resolvedEmail.isEmpty) {
      throw AuthException(
        'Recovery session is missing. Please open the reset link again.',
      );
    }

    final profileRow = await client
        .from('User')
        .select('user_id, username, email')
        .ilike('email', resolvedEmail)
        .maybeSingle();

    if (profileRow == null) {
      throw AuthException(
        'No matching account was found for this recovery email.',
      );
    }

    final trimmedPassword = newPassword.trim();
    final hashedPassword = PasswordHasher.hash(trimmedPassword);
    final row = Map<String, dynamic>.from(profileRow);
    final userId = row['user_id'];

    await _updateAuthPasswordAllowSame(trimmedPassword);

    try {
      await client
          .from('User')
          .update({'password': hashedPassword})
          .eq('email', resolvedEmail);
      return;
    } on PostgrestException {
      if (userId != null) {
        await client
            .from('User')
            .update({'password': hashedPassword})
            .eq('user_id', userId);
        return;
      }
      rethrow;
    }
  }

  Future<void> _updateAuthPasswordAllowSame(String password) async {
    try {
      await client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      if (_isSamePasswordError(error)) {
        return;
      }
      rethrow;
    }
  }

  bool _isSamePasswordError(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('same as the old password') ||
        message.contains('same as the current password') ||
        message.contains('must be different from the old password') ||
        message.contains('new password should be different');
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  Future<void> updateProfilePhoto({
    required int userId,
    required String profilePhotoPath,
    String? email,
  }) async {
    final normalizedPath = profilePhotoPath.trim();
    if (normalizedPath.isEmpty) {
      throw AuthException('Profile photo path cannot be empty.');
    }

    final updatedById = await _updateProfilePhotoByUserId(
      userId: userId,
      profilePhotoPath: normalizedPath,
    );
    if (updatedById) {
      return;
    }

    final normalizedEmail = email?.trim().toLowerCase() ?? '';
    if (normalizedEmail.isNotEmpty) {
      final updatedByEmail = await _updateProfilePhotoByEmail(
        email: normalizedEmail,
        profilePhotoPath: normalizedPath,
      );
      if (updatedByEmail) {
        return;
      }
    }

    throw AuthException(
      'Profile photo uploaded, but no user row was updated. Check RLS UPDATE policy for table "User".',
    );
  }

  Future<bool> _updateProfilePhotoByUserId({
    required int userId,
    required String profilePhotoPath,
  }) async {
    final response = await client
        .from('User')
        .update({'profile_photo': profilePhotoPath})
        .eq('user_id', userId)
        .select('user_id');

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.isNotEmpty;
  }

  Future<bool> _updateProfilePhotoByEmail({
    required String email,
    required String profilePhotoPath,
  }) async {
    final response = await client
        .from('User')
        .update({'profile_photo': profilePhotoPath})
        .ilike('email', email)
        .select('user_id');

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.isNotEmpty;
  }
}
