class Product {
  final String id;
  final String name;
  final String category;
  final String defaultUnit;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      defaultUnit: json['default_unit'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

class InventoryLot {
  final String id;
  final String productId;
  final double quantity;
  final String unit;
  final String? locationId; // Relacionado con locations
  final String locationName; // Para compatibilidad
  final String status;
  final DateTime? expiresOn;
  final String? notes;
  final String? source;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Product? product; // Joined product data
  final Location? locationData; // Joined location data

  InventoryLot({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unit,
    this.locationId,
    required this.locationName,
    required this.status,
    this.expiresOn,
    this.notes,
    this.source,
    required this.createdAt,
    this.updatedAt,
    this.product,
    this.locationData,
  });

  factory InventoryLot.fromJson(Map<String, dynamic> json) {
    return InventoryLot(
      id: json['id'],
      productId: json['product_id'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'uds',
      locationId: json['location_id'],
      locationName: json['locations']?['name'] ?? json['location'] ?? 'Despensa',
      status: json['status'] ?? 'ok',
      expiresOn: json['expires_on'] != null ? DateTime.parse(json['expires_on']) : null,
      notes: json['notes'],
      source: json['source'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      product: json['products'] != null ? Product.fromJson(json['products']) : null,
      locationData: json['locations'] != null ? Location.fromJson(json['locations']) : null,
    );
  }

  // Visual traffic light indicator
  String get statusColor {
    if (expiresOn == null) return 'ok';
    final now = DateTime.now();
    final difference = expiresOn!.difference(now).inDays;
    
    if (expiresOn!.isBefore(now)) return 'red'; // Vencido
    if (difference <= 7) return 'yellow'; // Vence pronto (dentro de una semana)
    return 'ok'; // OK
  }
}

class Location {
  final String id;
  final String name;
  final String? type;

  Location({required this.id, required this.name, this.type});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class ShoppingItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String priority;
  final String category;
  final String? notes;
  final bool completed;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.priority,
    required this.category,
    this.notes,
    required this.completed,
    required this.createdAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Sin nombre',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'uds',
      priority: json['priority'] ?? 'media',
      category: json['category'] ?? 'Despensa',
      notes: json['notes'],
      completed: json['completed'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
