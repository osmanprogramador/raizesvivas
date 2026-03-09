// Content model for QR code content
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentModel {
  final String id;
  final String qrCodeId;
  final String title;
  final String description;
  final String category;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentModel({
    required this.id,
    required this.qrCodeId,
    required this.title,
    required this.description,
    required this.category,
    this.imagePath,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qr_code_id': qrCodeId,
      'title': title,
      'description': description,
      'category': category,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Map
  factory ContentModel.fromMap(Map<String, dynamic> map) {
    // Helper for Timestamp/String compatibility
    DateTime toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return ContentModel(
      id: map['id'] as String,
      qrCodeId: map['qr_code_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      imagePath: map['image_path'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      createdAt: toDateTime(map['created_at']),
      updatedAt: toDateTime(map['updated_at']),
    );
  }

  // Copy with method for updates
  ContentModel copyWith({
    String? id,
    String? qrCodeId,
    String? title,
    String? description,
    String? category,
    String? imagePath,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContentModel(
      id: id ?? this.id,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
