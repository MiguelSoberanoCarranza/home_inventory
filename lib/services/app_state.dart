import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/supabase_service.dart';

class AppState with ChangeNotifier {
  final _service = SupabaseService();

  // Private backing fields
  List<Product> _products = [];
  List<InventoryLot> _inventory = [];
  List<ShoppingItem> _shoppingList = [];
  List<Location> _locations = [];

  // Public getters (immutable)
  List<Product> get products => List.unmodifiable(_products);
  List<InventoryLot> get inventory => List.unmodifiable(_inventory);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  List<Location> get locations => List.unmodifiable(_locations);

  // State
  bool isLoading = false;
  String? errorMessage;
  String? lastError;

  Future<void> init() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchProducts(),
        fetchInventory(),
        fetchShoppingList(),
        fetchLocations(),
      ]);
    } catch (e) {
      errorMessage = 'Error al cargar datos: $e';
      debugPrint('Error inicializando app: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    lastError = error;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
    notifyListeners();
  }

  Future<bool> fetchProducts() async {
    final result = await _service.getProducts();
    if (result.isSuccess) {
      _products = result.data!;
      notifyListeners();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> fetchInventory() async {
    final result = await _service.getInventory();
    if (result.isSuccess) {
      _inventory = result.data!;
      notifyListeners();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> fetchShoppingList() async {
    final result = await _service.getShoppingList();
    if (result.isSuccess) {
      _shoppingList = result.data!;
      notifyListeners();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> fetchLocations() async {
    final result = await _service.getLocations();
    if (result.isSuccess) {
      _locations = result.data!;
      notifyListeners();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  // Inventory actions
  Future<bool> addOrEditLot(Map<String, dynamic> data) async {
    final result = await _service.upsertInventoryLot(data);
    if (result.isSuccess) {
      await fetchInventory();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> deleteLot(String id) async {
    final result = await _service.deleteInventoryLot(id);
    if (result.isSuccess) {
      await fetchInventory();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  // Shopping actions
  Future<bool> addOrEditShoppingItem(Map<String, dynamic> data) async {
    final result = await _service.upsertShoppingItem(data);
    if (result.isSuccess) {
      await fetchShoppingList();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> deleteShoppingItem(String id) async {
    final result = await _service.deleteShoppingItem(id);
    if (result.isSuccess) {
      await fetchShoppingList();
      return true;
    } else {
      _setError(result.error);
      return false;
    }
  }

  Future<bool> toggleShoppingItem(String id, bool completed) async {
    // Optimistic UI update
    final index = _shoppingList.indexWhere((item) => item.id == id);
    if (index != -1) {
      final old = _shoppingList[index];
      _shoppingList[index] = ShoppingItem(
        id: old.id,
        name: old.name,
        quantity: old.quantity,
        unit: old.unit,
        priority: old.priority,
        category: old.category,
        notes: old.notes,
        completed: completed,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }

    final result = await _service.toggleShoppingComplete(id, completed);
    if (result.isSuccess) {
      // Opcional: recargar después, la UI ya está actualizada.
      await fetchShoppingList();
      return true;
    } else {
      // Si falla, revertir recargando de la base de datos
      await fetchShoppingList();
      _setError(result.error);
      return false;
    }
  }

  // Analytics helper (Dashboard)
  int get totalProducts => _products.length;
  int get totalLots => _inventory.where((lot) => lot.quantity > 0).length;
  int get expiringSoonCount =>
      _inventory.where((lot) => lot.quantity > 0 && lot.statusColor == 'yellow').length;
  int get expiredCount =>
      _inventory.where((lot) => lot.quantity > 0 && lot.statusColor == 'red').length;
  int get pendingShoppingItems =>
      _shoppingList.where((item) => !item.completed).length;

  Map<String, int> get countByLocation {
    final counts = <String, int>{};
    for (var lot in _inventory.where((lot) => lot.quantity > 0)) {
      counts[lot.locationName] = (counts[lot.locationName] ?? 0) + 1;
    }
    return counts;
  }
}