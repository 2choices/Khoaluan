import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double? costPrice;
  final double discountAmount;
  final double total;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    this.costPrice,
    this.discountAmount = 0.0,
    required this.total,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String,
      variantName: json['variant_name'] as String?,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      discountAmount:
          (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'sku': sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'discount_amount': discountAmount,
      'total': total,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? variantId,
    String? productName,
    String? variantName,
    String? sku,
    int? quantity,
    double? unitPrice,
    double? costPrice,
    double? discountAmount,
    double? total,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        variantId,
        productName,
        variantName,
        sku,
        quantity,
        unitPrice,
        costPrice,
        discountAmount,
        total,
        createdAt,
        updatedAt,
      ];
}
