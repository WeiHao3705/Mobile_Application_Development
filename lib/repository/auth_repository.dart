import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';
import '../services/password_hasher.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  static const String _loginSelectFields =
      'user_id, username, full_name, email, height, current_weight, target_weight, is_admin, password';

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

    if (storedPassword.isNotEmpty && storedPassword != hashedPassword) {
      await _upgradePasswordHash(
        userId: row['user_id'],
        hashedPassword: hashedPassword,
      );
    }

    return LoginUser.fromMap(row);
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
}
