import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aerobic.dart';

class AerobicRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAerobicActivity() async {
    try{
      final response = await _supabase
          .from('Aerobic_Activity')
          .select('aerobic_name, caloriesPerKM');
      return List<Map<String, dynamic>>.from(response);

    } catch(e) {
      print('Error to fetch aerobic activity record : $e');
      return [];
    }
  }


}