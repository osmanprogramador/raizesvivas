import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/content_model.dart';
import '../models/scan_history_model.dart';
import '../models/audit_log_model.dart';

class FirestoreService {
  // Singleton
  FirestoreService._privateConstructor();
  static final FirestoreService instance =
      FirestoreService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Add Storage instance

  // Collections
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _content => _db.collection('content');
  CollectionReference get _history => _db.collection('scan_history');
  CollectionReference get _auditLogs => _db.collection('audit_logs');

  // --- STORAGE METHODS ---
  Future<String?> uploadImage(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      // Set metadata to improve compatibility
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': _auth.currentUser?.uid ?? 'unknown'},
      );

      final snapshot = await ref.putFile(file, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('FirestoreService: Upload Image error: $e');
      // Re-throw to allow UI to catch the specific message
      throw Exception('Erro no upload: $e');
    }
  }

  Future<String?> uploadImageWeb(Uint8List bytes, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$folder/$fileName');

      // Specify content type for web to ensure it displays correctly
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded_by': _auth.currentUser?.uid ?? 'unknown'},
      );

      final snapshot = await ref.putData(bytes, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('FirestoreService: Upload Web Image error: $e');
      throw Exception('Erro no upload web: $e');
    }
  }

  // --- AUTH METHODS ---

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> login(String email, String password) async {
    try {
      debugPrint('FirestoreService: Tentando login com email: "$email"');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint(
          'FirestoreService: Login Firebase Auth OK! UID: ${credential.user?.uid}');

      if (credential.user != null) {
        final uid = credential.user!.uid;
        var user = await getUser(uid);

        // Se não existe perfil no Firestore OU se o perfil está corrompido (email/role null)
        if (user == null ||
            user.email.isEmpty ||
            user.role == UserRole.viewer) {
          debugPrint(
              'FirestoreService: Perfil ausente ou corrompido, recriando para $email');
          final now = DateTime.now();
          user = UserModel(
            id: uid,
            username: email.trim(),
            email: email.trim(),
            fullName: 'Administrador',
            role: UserRole.superAdmin,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );
          await _users.doc(uid).set(user.toMap());
          debugPrint('FirestoreService: Perfil recriado com sucesso');
        }

        debugPrint(
            'FirestoreService: Retornando usuário: ${user.email}, role: ${user.role.value}');
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Login error: $e');
      rethrow;
    }
  }

  Future<String?> signUp(String email, String password, String fullName) async {
    try {
      // 1. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Check if there is a pre-approved profile (ID == Email)
      final preApprovedDoc = await _users.doc(email.trim()).get();

      if (preApprovedDoc.exists) {
        // 3. Migrate profile to new UID
        final Map<String, dynamic> data =
            preApprovedDoc.data() as Map<String, dynamic>;

        // Update ID and other consistent fields
        data['id'] = uid;
        data['full_name'] =
            fullName; // Update name provided at user signup if desired, or keep admin's.
        // Let's prefer user's or keep admin's?
        // Let's specificly allow user to set name if admin didn't set a better one,
        // but admin form requires name. Let's just update UpdateAt.

        // Actually, we should use UserModel.fromMap to be safe
        UserModel user = UserModel.fromMap(data);
        user = user.copyWith(
            id: uid, fullName: fullName, lastLoginAt: DateTime.now());

        // Save to new UID
        await _users.doc(uid).set(user.toMap());

        // Delete old Invite doc
        await _users.doc(email.trim()).delete();

        return null; // Success (no error)
      } else {
        // 4. Strict Mode: If not pre-approved, reject.
        await credential.user?.delete();
        return 'Email não cadastrado previamente pelo administrador.';
      }
    } catch (e) {
      debugPrint('FirestoreService: SignUp error: $e');
      return e.toString(); // Return error message
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- USER METHODS ---

  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('FirestoreService.getUser: Buscando UID: $uid');
      final doc = await _users.doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id; // Ensure ID is present

        debugPrint('FirestoreService.getUser: Dados brutos do Firestore:');
        debugPrint('  - id: ${data['id']}');
        debugPrint('  - email: ${data['email']}');
        debugPrint('  - role: ${data['role']}');
        debugPrint('  - is_active: ${data['is_active']}');
        debugPrint('  - username: ${data['username']}');

        final user = UserModel.fromMap(data);

        debugPrint('FirestoreService.getUser: UserModel criado:');
        debugPrint('  - email: ${user.email}');
        debugPrint('  - role: ${user.role.value}');
        debugPrint('  - isActive: ${user.isActive}');
        debugPrint('  - canManageUsers: ${user.canManageUsers}');

        return user;
      }

      debugPrint(
          'FirestoreService.getUser: Documento não existe ou está vazio');
      return null;
    } catch (e, stackTrace) {
      debugPrint('FirestoreService: Get User error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // NOTE: This creates the FIRESTORE document.
  // Creating the Auth credentials for another user requires a secondary Firebase App instance
  // or a Cloud Function to avoid logging out the current admin.
  // For now, we save the user profile.
  Future<bool> createUserProfile(UserModel user) async {
    try {
      await _users.doc(user.id).set(user.toMap());
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.create,
        entityType: 'user',
        entityId: user.id,
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Create User Profile error: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await _users.doc(user.id).update(user.toMap());
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.update,
        entityType: 'user',
        entityId: user.id,
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Update User error: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      await _users.doc(uid).delete();
      // Note: Auth account deletion requires Cloud Function or Admin SDK
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.delete,
        entityType: 'user',
        entityId: uid,
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Delete User error: $e');
      return false;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _users.get();
      return snapshot.docs.map((doc) {
        final data =
            Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id; // Ensure ID is present
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('FirestoreService: Get All Users error: $e');
      return [];
    }
  }

  // --- CONTENT METHODS ---

  Future<List<ContentModel>> getAllContents() async {
    try {
      final snapshot =
          await _content.orderBy('updated_at', descending: true).get();
      return snapshot.docs
          .map(
              (doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FirestoreService: Get All Content error: $e');
      return [];
    }
  }

  Future<ContentModel?> getContentById(String id, {Source? source}) async {
    try {
      final doc = await _content
          .doc(id)
          .get(GetOptions(source: source ?? Source.serverAndCache));
      if (doc.exists) {
        return ContentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Get Content By Id error: $e');
      return null;
    }
  }

  Future<ContentModel?> getContentByQrCodeId(String qrCodeId,
      {Source? source}) async {
    try {
      final snapshot = await _content
          .where('qr_code_id', isEqualTo: qrCodeId)
          .limit(1)
          .get(GetOptions(source: source ?? Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        return ContentModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Get Content By QR error: $e');
      rethrow; // Rethrow to allow ContentProvider to handle fallback
    }
  }

  Stream<List<ContentModel>> streamContents() {
    return _content
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
              (doc) => ContentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<bool> createContent(ContentModel content) async {
    try {
      await _content.doc(content.id).set(content.toMap());
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.create,
        entityType: 'content',
        entityId: content.id,
        details: 'Created content: ${content.title}',
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Create Content error: $e');
      return false;
    }
  }

  Future<bool> updateContent(ContentModel content) async {
    try {
      await _content.doc(content.id).update(content.toMap());
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.update,
        entityType: 'content',
        entityId: content.id,
        details: 'Updated content: ${content.title}',
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Update Content error: $e');
      return false;
    }
  }

  Future<bool> deleteContent(String id) async {
    try {
      await _content.doc(id).delete();
      await logAction(
        userId: _auth.currentUser?.uid ?? 'system',
        action: AuditAction.delete,
        entityType: 'content',
        entityId: id,
      );
      return true;
    } catch (e) {
      debugPrint('FirestoreService: Delete Content error: $e');
      return false;
    }
  }

  // --- HISTORY & LOGS ---

  Future<void> saveScan(ScanHistoryModel scan) async {
    try {
      await _history.doc(scan.id).set(scan.toMap());
    } catch (e) {
      debugPrint('FirestoreService: Save Scan error: $e');
    }
  }

  Future<List<ScanHistoryModel>> getScanHistory() async {
    // In a real app, query by user_id or device_id if needed.
    // Assuming local history is personalized, but here we just fetch all for demo/admin
    // OR we might want to store history in a subcollection of users.
    // For now, global list as per existing model implication (though it was local).
    try {
      final snapshot = await _history
          .orderBy('scanned_at', descending: true)
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) =>
              ScanHistoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FirestoreService: Get History error: $e');
      return [];
    }
  }

  Future<void> logAction({
    required String userId,
    required AuditAction action,
    required String entityType,
    String? entityId,
    String? details,
  }) async {
    try {
      final log = AuditLogModel(
        id: _auditLogs.doc().id,
        userId: userId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        details: details,
        createdAt: DateTime.now(),
      );
      await _auditLogs.doc(log.id).set(log.toMap());
    } catch (e) {
      debugPrint('FirestoreService: Log Action error: $e');
    }
  }
}
