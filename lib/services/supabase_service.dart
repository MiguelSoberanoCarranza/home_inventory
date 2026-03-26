import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_models.dart';
import '../utils/result.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  String get _userId {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    return user.id;
  }

  // --- Products ---
  Future<Result<List<Product>>> getProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('user_id', _userId)
          .order('name', ascending: true);
      final products =
          (response as List).map((json) => Product.fromJson(json)).toList();
      return Result.success(products);
    } on PostgrestException catch (e) {
      return Result.failure('Error de base de datos: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<Product>> upsertProduct(Map<String, dynamic> data) async {
    try {
      data['user_id'] = _userId;
      final response = await supabase
          .from('products')
          .upsert(data)
          .select()
          .single();
      return Result.success(Product.fromJson(response));
    } on PostgrestException catch (e) {
      return Result.failure('Error al guardar producto: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  // --- Inventory Lots ---
  Future<Result<List<InventoryLot>>> getInventory() async {
    try {
      final response = await supabase
          .from('inventory_lots')
          .select('*, products(*), locations(*)')
          .eq('user_id', _userId)
          .order('expires_on', ascending: true);
      final inventory =
          (response as List).map((json) => InventoryLot.fromJson(json)).toList();
      return Result.success(inventory);
    } on PostgrestException catch (e) {
      return Result.failure('Error de base de datos: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> upsertInventoryLot(Map<String, dynamic> data) async {
    try {
      data['user_id'] = _userId;
      await supabase.from('inventory_lots').upsert(data);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al guardar lote: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> deleteInventoryLot(String id) async {
    try {
      await supabase.from('inventory_lots').delete().match({'id': id, 'user_id': _userId});
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al eliminar lote: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  // --- Shopping List ---
  Future<Result<List<ShoppingItem>>> getShoppingList() async {
    try {
      final response = await supabase
          .from('shopping_list')
          .select()
          .eq('user_id', _userId)
          .order('completed', ascending: false)
          .order('priority', ascending: true);
      final items =
          (response as List).map((json) => ShoppingItem.fromJson(json)).toList();
      return Result.success(items);
    } on PostgrestException catch (e) {
      return Result.failure('Error de base de datos: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> upsertShoppingItem(Map<String, dynamic> data) async {
    try {
      data['user_id'] = _userId;
      await supabase.from('shopping_list').upsert(data);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al guardar item: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> deleteShoppingItem(String id) async {
    try {
      await supabase.from('shopping_list').delete().match({'id': id, 'user_id': _userId});
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al eliminar item: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> toggleShoppingComplete(String id, bool completed) async {
    try {
      await supabase
          .from('shopping_list')
          .update({'completed': completed})
          .match({'id': id, 'user_id': _userId});
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al actualizar item: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<List<Location>>> getLocations() async {
    try {
      final response = await supabase.from('locations').select().eq('user_id', _userId);
      final locations =
          (response as List).map((json) => Location.fromJson(json)).toList();
      return Result.success(locations);
    } on PostgrestException catch (e) {
      return Result.failure('Error de base de datos: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  // --- Recipes ---
  Future<Result<List<Recipe>>> getRecipes() async {
    try {
      final response = await supabase
          .from('recipes')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      final recipes =
          (response as List).map((json) => Recipe.fromJson(json)).toList();
      return Result.success(recipes);
    } on PostgrestException catch (e) {
      return Result.failure('Error de base de datos: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> upsertRecipe(Map<String, dynamic> data) async {
    try {
      data['user_id'] = _userId;
      await supabase.from('recipes').upsert(data);
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al guardar receta: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }

  Future<Result<void>> deleteRecipe(String id) async {
    try {
      await supabase.from('recipes').delete().match({'id': id, 'user_id': _userId});
      return const Result.success(null);
    } on PostgrestException catch (e) {
      return Result.failure('Error al eliminar receta: ${e.message}');
    } catch (e) {
      return Result.failure('Error inesperado: $e');
    }
  }
}