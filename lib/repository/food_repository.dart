import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/models/food.dart';
import 'dart:developer';

class FoodRepository{
  final SupabaseClient supabase;

  FoodRepository({required this.supabase});

  //CREATE
  Future<Food> createFood(Food food) async{
    try{
      log("🟦 FoodRepository.createFood START");
      log("📝 Inserting food: ${food.foodName}");
      log("📊 Food data: ${food.toJson()}");

      final response = await supabase
          .from('Food')
          .insert(food.toJson())
          .select()
          .single();

      log("✅ Insert success: $response");
      return Food.fromJson(response);

    } on PostgrestException catch (e){
      log("❌ PostgrestException Error");
      log("❌ Error Code: ${e.code}");
      log("❌ Error Message: ${e.message}");
      log("❌ Error Details: ${e.details}");
      log("❌ Full Error: $e");
      rethrow;
    } catch (e){
      log("❌ Unexpected error in createFood");
      log("❌ Error Type: ${e.runtimeType}");
      log("❌ Error: $e");
      rethrow;
    }
  }

  //READ
  Future<List<Food>> getFoodsByUser(int userId) async{
    try{
      final response = await supabase
          .from('Food')
          .select()
          .eq('user_id', userId);

      log("Data fetched successfully.");

      return (response as List)
          .map((json) => Food.fromJson(json))
          .toList();
    }catch (e){
      log("Fetch failed. Error", error: e);
      rethrow;
    }
  }

  //UPDATE
  Future<Food> updateFood(Food food) async{
    try{
      final response = await supabase
          .from('Food')
          .update(food.toJson())
          .eq('food_id', food.foodId)
          .select()
          .single();

      log("Update success: $response");

      return Food.fromJson(response);

    }catch (e){
      log("Update failed. Error", error: e);
      rethrow;
    }
  }

  //DELETE
  Future<void> deleteFood(int foodId) async{
    try{
      await supabase
          .from('Food')
          .delete()
          .eq('food_id', foodId);

      log("Delete success.");
    }catch (e){
      log("Delete failed. Error", error: e);
      rethrow;
    }
  }

  //READ ALL
  Future<List<Food>> getAllFoods() async{
    try{
      final response = await supabase
          .from('Food')
          .select();

      log("All foods fetched successfully.");

      return (response as List)
          .map((json) => Food.fromJson(json))
          .toList();
    }catch (e){
      log("Fetch all failed. Error", error: e);
      rethrow;
    }
  }

  //SEARCH
  Future<List<Food>> searchFoods(String query) async{
    try{
      final response = await supabase
          .from('Food')
          .select()
          .ilike('food_name', '%$query%');

      log("Search completed. Found ${(response as List).length} results");

      return (response as List)
          .map((json) => Food.fromJson(json))
          .toList();
    }catch (e){
      log("Search failed. Error", error: e);
      rethrow;
    }
  }

}