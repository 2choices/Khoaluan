import 'package:equatable/equatable.dart';

class Inventory extends Equatable {
  final String id;
  final String tenantId;
  final String warehouseId;
  final String productId;
  final String? variantId;
  final int quantity;
  final int reservedQuantity;
  final int minQuantity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Inventory({
    required this.id,
    required this.tenantId,
    required this.warehouseId,
    required this.productId,
    this.variantId,
    this.quantity = 0,
    this.reservedQuantity = 0,
    this.minQuantity = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Available quantity = quantity - reservedQuantity
  int get availableQuantity => quantity - reservedQuantity;

  /// Whether stock is below minimum threshold
  bool get isLowStock => availableQuantity <= minQuantity;

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      reservedQuantity: json['reserved_quantity'] as int? ?? 0,
      minQuantity: json['min_quantity'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'warehouse_id': warehouseId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      'min_quantity': minQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Inventory copyWith({
    String? id,
    String? tenantId,
    String? warehouseId,
    String? productId,
    String? variantId,
    int? quantity,
    int? reservedQuantity,
    int? minQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inventory(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      warehouseId: warehouseId ?? this.warehouseId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      reservedQuantity: reservedQuantity ?? this.reservedQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        warehouseId,
        productId,
        variantId,
        quantity,
        reservedQuantity,
        minQuantity,
        createdAt,
        updatedAt,
      ];
}
