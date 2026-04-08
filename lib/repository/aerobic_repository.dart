import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aerobic.dart';

class AerobicRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Aerobic>> fetchUserRecords(String userId) async {
    try{
      final response = await _supabase
        .from('AerobicExercise')
        .select()
        .eq('user_id', userId)
        .order('start_at', ascending:false);

      if(response is List) {
        return response.map((data) {
          if(data is Map<String, dynamic>) {
            return Aerobic.fromJson(data);
          }
          return null;
        }).whereType<Aerobic>().toList();
      }

        return[];
    } catch(e) {
      print('Error fetching user records: $e');
      throw Exception('Failed to fetch user records: $e');
    }
  }
}