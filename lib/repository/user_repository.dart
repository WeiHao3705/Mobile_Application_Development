import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  /// Columns safe to load into the app. Never include `password` here.
  static const String _publicColumns =
      'user_id, username, full_name, email, height, current_weight, '
      'target_weight, is_admin, profile_photo, date_of_birth, gender';

  Future<List<AppUser>> fetchUsers() async {
    final response = await client.from('User').select(_publicColumns);
    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> fetchUserByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final response = await client
        .from('User')
        .select(_publicColumns)
        .ilike('email', normalizedEmail)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AppUser.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> createUserProfile(SignUpProfileData profile) async {
    final payload = profile.toInsertMap();
    await client.from('User').insert(payload);
  }
}