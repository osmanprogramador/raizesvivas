/// Enum for audit action types
library;
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  create('create', 'Criou'),
  update('update', 'Atualizou'),
  delete('delete', 'Deletou'),
  login('login', 'Login'),
  logout('logout', 'Logout'),
  activate('activate', 'Ativou'),
  deactivate('deactivate', 'Desativou'),
  resetPassword('reset_password', 'Redefiniu senha'),
  changePassword('change_password', 'Alterou senha');

  final String value;
  final String displayName;

  const AuditAction(this.value, this.displayName);

  static AuditAction fromString(String value) {
    return AuditAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => AuditAction.update,
    );
  }
}

/// Audit Log Model
class AuditLogModel {
  final String id;
  final String userId;
  final AuditAction action;
  final String entityType; // 'user', 'content', etc.
  final String? entityId;
  final String? details; // JSON details
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action.value,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'ip_address': ipAddress,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore Map
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    DateTime toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return AuditLogModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      action: AuditAction.fromString(map['action'] as String),
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String?,
      details: map['details'] as String?,
      ipAddress: map['ip_address'] as String?,
      createdAt: toDateTime(map['created_at']),
    );
  }

  String getDescription() {
    return '${action.displayName} $entityType${entityId != null ? ' #${entityId!.substring(0, 8)}' : ''}';
  }
}
