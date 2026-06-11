import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String tenantId;
  final String? categoryId;
  final String name;
  final String slug;
  final String? sku;
  final String? barcode;
  final double basePrice;
  final double? costPrice;
  final double? comparePrice;
  final double taxRate;
  final bool taxInclusive;
  final Map<String, dynamic> attributes;
  final String? baseUnit;
  final bool isActive;
  final bool isFeatured;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.tenantId,
    this.categoryId,
    required this.name,
    required this.slug,
    this.sku,
    this.barcode,
    required this.basePrice,
    this.costPrice,
    this.comparePrice,
    this.taxRate = 0.0,
    this.taxInclusive = true,
    this.attributes = const {},
    this.baseUnit,
    this.isActive = true,
    this.isFeatured = false,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num?)?.toDouble(),
      comparePrice: (json['compare_price'] as num?)?.toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxInclusive: json['tax_inclusive'] as bool? ?? true,
      attributes:
          (json['attributes'] as Map<String, dynamic>?) ?? const {},
      baseUnit: json['base_unit'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'sku': sku,
      'barcode': barcode,
      'base_price': basePrice,
      'cost_price': costPrice,
      'compare_price': comparePrice,
      'tax_rate': taxRate,
      'tax_inclusive': taxInclusive,
      'attributes': attributes,
      'base_unit': baseUnit,
      'is_active': isActive,
      'is_featured': isFeatured,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? tenantId,
    String? categoryId,
    String? name,
    String? slug,
    String? sku,
    String? barcode,
    double? basePrice,
    double? costPrice,
    double? comparePrice,
    double? taxRate,
    bool? taxInclusive,
    Map<String, dynamic>? attributes,
    String? baseUnit,
    bool? isActive,
    bool? isFeatured,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      basePrice: basePrice ?? this.basePrice,
      costPrice: costPrice ?? this.costPrice,
      comparePrice: comparePrice ?? this.comparePrice,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      attributes: attributes ?? this.attributes,
      baseUnit: baseUnit ?? this.baseUnit,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        categoryId,
        name,
        slug,
        sku,
        barcode,
        basePrice,
        costPrice,
        comparePrice,
        taxRate,
        taxInclusive,
        attributes,
        baseUnit,
        isActive,
        isFeatured,
        tags,
        createdAt,
        updatedAt,
      ];
}
