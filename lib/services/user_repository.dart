import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class UserRepository {
  UserRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<List<AppUser>> fetchUsers() async {
    final response = await client.from('User').select();
    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(AppUser.fromMap).toList();
  }
}
