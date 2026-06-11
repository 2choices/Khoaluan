import 'package:equatable/equatable.dart';

import 'enums.dart';

class Customer extends Equatable {
  final String id;
  final String tenantId;
  final String? groupId;
  final String? code;
  final String fullName;
  final String? phone;
  final String? email;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final LoyaltyTier loyaltyTier;
  final int loyaltyPoints;
  final double totalSpent;
  final int totalOrders;
  final double debtAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    required this.tenantId,
    this.groupId,
    this.code,
    required this.fullName,
    this.phone,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.loyaltyTier = LoyaltyTier.none,
    this.loyaltyPoints = 0,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    this.debtAmount = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      groupId: json['group_id'] as String?,
      code: json['code'] as String?,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      loyaltyTier: json['loyalty_tier'] != null
          ? LoyaltyTier.fromJson(json['loyalty_tier'] as String)
          : LoyaltyTier.none,
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      debtAmount: (json['debt_amount'] as num?)?.toDouble() ?? 0.0,
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
      'group_id': groupId,
      'code': code,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
      'loyalty_tier': loyaltyTier.toJson(),
      'loyalty_points': loyaltyPoints,
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'debt_amount': debtAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? tenantId,
    String? groupId,
    String? code,
    String? fullName,
    String? phone,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    LoyaltyTier? loyaltyTier,
    int? loyaltyPoints,
    double? totalSpent,
    int? totalOrders,
    double? debtAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      groupId: groupId ?? this.groupId,
      code: code ?? this.code,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      debtAmount: debtAmount ?? this.debtAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        groupId,
        code,
        fullName,
        phone,
        email,
        gender,
        dateOfBirth,
        address,
        loyaltyTier,
        loyaltyPoints,
        totalSpent,
        totalOrders,
        debtAmount,
        createdAt,
        updatedAt,
      ];
}
