import 'package:equatable/equatable.dart';

import 'enums.dart';

class User extends Equatable {
  final String id;
  final String tenantId;
  final String? branchId;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final UserStatus status;
  final String? pinCode;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.tenantId,
    this.branchId,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
    this.status = UserStatus.active,
    this.pinCode,
    this.lastLoginAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String?,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] != null
          ? UserStatus.fromJson(json['status'] as String)
          : UserStatus.active,
      pinCode: json['pin_code'] as String?,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
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
      'branch_id': branchId,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'email': email,
      'status': status.toJson(),
      'pin_code': pinCode,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? fullName,
    String? avatarUrl,
    String? phone,
    String? email,
    UserStatus? status,
    String? pinCode,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      pinCode: pinCode ?? this.pinCode,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        branchId,
        fullName,
        avatarUrl,
        phone,
        email,
        status,
        pinCode,
        lastLoginAt,
        createdAt,
        updatedAt,
      ];
}
