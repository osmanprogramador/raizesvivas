import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for user roles
enum UserRole {
  superAdmin('super_admin', 'Super Administrador'),
  admin('admin', 'Administrador'),
  editor('editor', 'Editor'),
  viewer('viewer', 'Visualizador');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.viewer,
    );
  }
}

/// Admin User Model adapted for Firestore
class UserModel {
  final String id; // This will be the Firebase Auth UID
  final String username; // Email is used as username/identifier
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final bool mustChangePassword;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime updatedAt;
  final String? updatedBy;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isActive = true,
    this.mustChangePassword = false,
    this.lastLoginAt,
    required this.createdAt,
    this.createdBy,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'role': role.value,
      'is_active': isActive, // Firestore stores booleans natively
      'must_change_password': mustChangePassword,
      'last_login_at':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'created_by': createdBy,
      'updated_at': Timestamp.fromDate(updatedAt),
      'updated_by': updatedBy,
    };
  }

  /// Create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper to safely get DateTime from Timestamp or String (legacy/migration safety)
    DateTime toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now(); // Fallback
    }

    return UserModel(
      id: map['id'] as String? ?? '', // Safety fallback
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String?,
      role: UserRole.fromString(map['role'] as String? ?? ''),
      isActive: map['is_active'] == true,
      mustChangePassword: map['must_change_password'] == true,
      lastLoginAt: map['last_login_at'] != null
          ? toDateTime(map['last_login_at'])
          : null,
      createdAt: toDateTime(map['created_at']),
      createdBy: map['created_by'] as String?,
      updatedAt: toDateTime(map['updated_at']),
      updatedBy: map['updated_by'] as String?,
    );
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isActive,
    bool? mustChangePassword,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get display name for role
  String get roleDisplayName => role.displayName;

  /// Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user can manage users
  bool get canManageUsers =>
      role == UserRole.superAdmin || role == UserRole.admin;

  /// Check if user can edit content
  bool get canEditContent => role != UserRole.viewer;

  /// Check if user can delete content
  bool get canDeleteContent =>
      role == UserRole.superAdmin || role == UserRole.admin;
}
