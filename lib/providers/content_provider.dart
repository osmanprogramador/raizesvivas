import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/content_model.dart';
import '../services/firestore_service.dart';

enum SyncStatus { syncing, synced, error }

class ContentProvider with ChangeNotifier {
  List<ContentModel> _contents = [];
  bool _isLoading = false;
  SyncStatus _syncStatus = SyncStatus.syncing;
  DateTime? _lastSynced;
  StreamSubscription<List<ContentModel>>? _subscription;

  List<ContentModel> get contents => _contents;
  bool get isLoading => _isLoading;
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSynced => _lastSynced;

  // Load all content (Real-time Stream)
  Future<void> loadContents() async {
    if (_subscription != null) return;

    _isLoading = true;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    _subscription = FirestoreService.instance.streamContents().listen(
      (data) {
        _contents = data;
        _isLoading = false;
        _syncStatus = SyncStatus.synced;
        _lastSynced = DateTime.now();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error loading contents stream: $e');
        _isLoading = false;
        _syncStatus = SyncStatus.error;
        notifyListeners();
      },
    );
  }

  // Get content by ID
  Future<ContentModel?> getContentById(String id) async {
    try {
      // First check local list
      final local = _contents.where((c) => c.id == id).firstOrNull;
      if (local != null) return local;

      return await FirestoreService.instance.getContentById(id);
    } catch (e) {
      debugPrint('Error getting content: $e');
      return null;
    }
  }

  // Get content by QR code ID
  // Get content by QR code ID
  Future<ContentModel?> getContentByQrCodeId(String qrCodeId) async {
    // First check local list
    final local = _contents.where((c) => c.qrCodeId == qrCodeId).firstOrNull;
    if (local != null) return local;

    try {
      // Try network first with a short timeout
      return await FirestoreService.instance
          .getContentByQrCodeId(qrCodeId)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint(
          'Network error or timeout fetching by QR, trying offline cache: $e');
      try {
        // Try cache fallback
        return await FirestoreService.instance
            .getContentByQrCodeId(qrCodeId, source: Source.cache);
      } catch (cacheError) {
        debugPrint('Cache error: $cacheError');
        return null;
      }
    }
  }

  // Create new content
  Future<bool> createContent(ContentModel content) async {
    try {
      return await FirestoreService.instance.createContent(content);
      // Stream will update the UI automatically
    } catch (e) {
      debugPrint('Error creating content: $e');
      return false;
    }
  }

  // Update content
  Future<bool> updateContent(ContentModel content) async {
    try {
      return await FirestoreService.instance.updateContent(content);
      // Stream will update the UI automatically
    } catch (e) {
      debugPrint('Error updating content: $e');
      return false;
    }
  }

  // Delete content
  Future<bool> deleteContent(String id) async {
    try {
      return await FirestoreService.instance.deleteContent(id);
      // Stream will update the UI automatically
    } catch (e) {
      debugPrint('Error deleting content: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Extension for list filtering compatibility
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
