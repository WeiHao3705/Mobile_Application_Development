import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';
import '../services/password_hasher.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  static const String _loginSelectFields =
      'user_id, username, full_name, email, height, current_weight, target_weight, is_admin, password, profile_photo, date_of_birth, gender';

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<LoginUser?> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();
    final hashedPassword = PasswordHasher.hash(normalizedPassword);

    final response = await client
        .from('User')
        .select(_loginSelectFields)
        .eq('username', normalizedUsername)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final row = Map<String, dynamic>.from(response);
    final storedPassword = row['password']?.toString() ?? '';

    if (!_passwordMatches(
      storedPassword: storedPassword,
      plainTextPassword: normalizedPassword,
      hashedPassword: hashedPassword,
    )) {
      return null;
    }

    // Establish Supabase Auth session so RLS-protected updates are allowed.
    await _ensureAuthSession(
      email: row['email']?.toString(),
      password: normalizedPassword,
    );

    if (storedPassword.isNotEmpty && storedPassword != hashedPassword) {
      await _upgradePasswordHash(
        userId: row['user_id'],
        hashedPassword: hashedPassword,
      );
    }

    return LoginUser.fromMap(row);
  }

  Future<void> _ensureAuthSession({
    required String? email,
    required String password,
  }) async {
    final normalizedEmail = email?.trim() ?? '';
    if (normalizedEmail.isEmpty) {
      return;
    }

    try {
      await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      return;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final shouldTryCreate = message.contains('invalid login credentials') ||
          message.contains('email not confirmed') ||
          message.contains('user not found') ||
          message.contains('invalid credentials');

      if (!shouldTryCreate) {
        return;
      }
    } catch (_) {
      return;
    }

    try {
      await ensureAuthIdentity(
        email: normalizedEmail,
        password: password,
      );
      await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
    } catch (_) {
      // Keep app login compatible even if auth session cannot be established.
    }
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
