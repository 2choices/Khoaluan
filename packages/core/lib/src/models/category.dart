import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String tenantId;
  final String? parentId;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.tenantId,
    this.parentId,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
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
      'tenant_id': tenantId,
      'parent_id': parentId,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? tenantId,
    String? parentId,
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        parentId,
        name,
        slug,
        description,
        imageUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
