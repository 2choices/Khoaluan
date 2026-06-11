import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// App-level user model that wraps Supabase [User] with tenant information,
/// roles, and permissions.
class AuthUser {
  final String id;
  final String email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String tenantId;
  final String? branchId;
  final List<String> roles;
  final List<String> permissions;

  const AuthUser({
    required this.id,
    required this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    required this.tenantId,
    this.branchId,
    this.roles = const [],
    this.permissions = const [],
  });

  /// Create an [AuthUser] from a Supabase [User] and optional profile metadata.
  ///
  /// The [profileData] map is expected to come from a query to the
  /// application's `users` table (or user_metadata) and should contain keys
  /// like `tenant_id`, `branch_id`, `roles`, `permissions`, etc.
  factory AuthUser.fromSupabaseUser(
    User user, {
    Map<String, dynamic>? profileData,
  }) {
    final meta = user.userMetadata ?? {};
    final profile = profileData ?? {};

    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      phone: user.phone,
      fullName: profile['full_name'] as String? ??
          meta['full_name'] as String?,
      avatarUrl: profile['avatar_url'] as String? ??
          meta['avatar_url'] as String?,
      tenantId: profile['tenant_id'] as String? ??
          meta['tenant_id'] as String? ??
          '',
      branchId: profile['branch_id'] as String? ??
          meta['branch_id'] as String?,
      roles: _parseStringList(profile['roles'] ?? meta['roles']),
      permissions:
          _parseStringList(profile['permissions'] ?? meta['permissions']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Create a copy with updated fields.
  AuthUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? tenantId,
    String? branchId,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Whether this user has a specific role.
  bool hasRole(String role) => roles.contains(role);

  /// Whether this user has a specific permission.
  bool hasPermission(String permission) => permissions.contains(permission);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'roles': roles,
      'permissions': permissions,
    };
  }

  @override
  String toString() => 'AuthUser(id: $id, email: $email, tenantId: $tenantId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
