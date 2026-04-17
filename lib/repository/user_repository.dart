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

  Future<void> createUserProfile(SignUpProfileData profile) async {
    final snakeCasePayload = profile.toInsertMap();

    try {
      await client.from('User').insert(snakeCasePayload);
    } on PostgrestException catch (error) {
      if (_isMissingColumn(error, 'phone_number')) {
        await _insertWithCamelCasePhone(profile, snakeCasePayload);
        return;
      }
      rethrow;
    }
  }

  Future<void> _insertWithCamelCasePhone(
    SignUpProfileData profile,
    Map<String, dynamic> snakeCasePayload,
  ) async {
    final camelCasePayload = Map<String, dynamic>.from(snakeCasePayload)
      ..remove('phone_number');

    if (profile.phoneNumber.isNotEmpty) {
      camelCasePayload['phoneNumber'] = profile.phoneNumber;
    }

    try {
      await client.from('User').insert(camelCasePayload);
    } on PostgrestException catch (error) {
      if (_isMissingColumn(error, 'phoneNumber')) {
        // Last fallback for schemas that do not yet include a phone column.
        final noPhonePayload = profile.toInsertMap(includePhoneNumber: false);
        await client.from('User').insert(noPhonePayload);
        return;
      }
      rethrow;
    }
  }

  bool _isMissingColumn(PostgrestException error, String columnName) {
    final message = error.message.toLowerCase();
    return message.contains(columnName.toLowerCase()) &&
        (message.contains('schema cache') || message.contains('column'));
  }
}