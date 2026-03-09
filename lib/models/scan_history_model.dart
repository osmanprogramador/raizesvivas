// Scan history model
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanHistoryModel {
  final String id;
  final String contentId;
  final String qrCodeId;
  final DateTime scannedAt;

  ScanHistoryModel({
    required this.id,
    required this.contentId,
    required this.qrCodeId,
    required this.scannedAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content_id': contentId,
      'qr_code_id': qrCodeId,
      'scanned_at': Timestamp.fromDate(scannedAt),
    };
  }

  // Create from Map
  factory ScanHistoryModel.fromMap(Map<String, dynamic> map) {
    DateTime toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      return DateTime.now();
    }

    return ScanHistoryModel(
      id: map['id'] as String,
      contentId: map['content_id'] as String,
      qrCodeId: map['qr_code_id'] as String,
      scannedAt: toDateTime(map['scanned_at']),
    );
  }
}
