import 'package:equatable/equatable.dart';

class Tenant extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? businessType;
  final String currency;
  final String timezone;
  final Map<String, dynamic> settings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.businessType,
    this.currency = 'VND',
    this.timezone = 'Asia/Ho_Chi_Minh',
    this.settings = const {},
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      businessType: json['business_type'] as String?,
      currency: json['currency'] as String? ?? 'VND',
      timezone: json['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
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
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'business_type': businessType,
      'currency': currency,
      'timezone': timezone,
      'settings': settings,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? slug,
    String? logoUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? businessType,
    String? currency,
    String? timezone,
    Map<String, dynamic>? settings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      businessType: businessType ?? this.businessType,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        logoUrl,
        phone,
        email,
        address,
        city,
        businessType,
        currency,
        timezone,
        settings,
        isActive,
        createdAt,
        updatedAt,
      ];
}
