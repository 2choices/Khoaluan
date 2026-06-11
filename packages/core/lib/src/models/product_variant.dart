import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final String id;
  final String productId;
  final String tenantId;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double? costPrice;
  final Map<String, dynamic> attributes;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.tenantId,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.costPrice,
    this.attributes = const {},
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      attributes:
          (json['attributes'] as Map<String, dynamic>?) ?? const {},
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'tenant_id': tenantId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'attributes': attributes,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? tenantId,
    String? name,
    String? sku,
    String? barcode,
    double? price,
    double? costPrice,
    Map<String, dynamic>? attributes,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      attributes: attributes ?? this.attributes,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        tenantId,
        name,
        sku,
        barcode,
        price,
        costPrice,
        attributes,
        imageUrl,
        isActive,
        createdAt,
        updatedAt,
      ];
}
