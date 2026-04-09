import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<LoginUser?> login({
    required String username,
    required String password,
  }) async {
    final response = await client
        .from('User')
        .select(
      'user_id, username, full_name, email, height, current_weight, target_weight, is_admin',
    )
        .eq('username', username)
        .eq('password', password)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return LoginUser.fromMap(Map<String, dynamic>.from(response));
  }
}
