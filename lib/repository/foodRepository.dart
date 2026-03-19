import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_application_development/models/food.dart';
import 'dart:developer';

class FoodRepository{
  final SupabaseClient supabase;

  FoodRepository({required this.supabase});

  //CREATE
  Future<Food> createFood(Food food) async{
    try{
      final response = await supabase
          .from('Food')
          .insert(food.toJson())
          .select()
          .single();

      log("Insert new food success: $response");

      return Food.fromJson(response);

    }catch (e){
      log("Insert failed. Error", error: e);
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

}