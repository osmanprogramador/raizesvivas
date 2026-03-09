import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isVisitorMode = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isVisitorMode => _isVisitorMode;
  bool get isLoading => _isLoading;

  // Check if current user is admin (has elevated privileges)
  bool get isAdmin =>
      _isAuthenticated &&
      !_isVisitorMode &&
      _currentUser != null &&
      (_currentUser!.role == UserRole.admin ||
          _currentUser!.role == UserRole.superAdmin);

  // Check if current user is super admin
  bool get isSuperAdmin =>
      _isAuthenticated &&
      !_isVisitorMode &&
      _currentUser != null &&
      _currentUser!.role == UserRole.superAdmin;

  // Check login status from Firebase Auth
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = FirestoreService.instance.currentUser;
      if (firebaseUser != null) {
        final user = await FirestoreService.instance.getUser(firebaseUser.uid);
        if (user != null && user.isActive) {
          _currentUser = user;
          _isAuthenticated = true;
          _isVisitorMode = false;
        } else {
          // User exists in Auth but not in Firestore or inactive
          await FirestoreService.instance.logout();
        }
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login as user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthProvider: Iniciando login para: $email');
      final user = await FirestoreService.instance.login(email, password);
      debugPrint(
          'AuthProvider: Resultado do login - user: ${user?.email}, role: ${user?.role.value}');

      if (user != null) {
        if (!user.isActive) {
          debugPrint('AuthProvider: Usuário inativo, fazendo logout');
          await FirestoreService.instance.logout();
          return false;
        }
        _currentUser = user;
        _isAuthenticated = true;
        _isVisitorMode = false;

        debugPrint('AuthProvider: Login bem sucedido!');
        debugPrint('  - isAuthenticated: $_isAuthenticated');
        debugPrint('  - isVisitorMode: $_isVisitorMode');
        debugPrint('  - currentUser: ${_currentUser?.email}');
        debugPrint('  - role: ${_currentUser?.role.value}');
        debugPrint('  - isAdmin getter: $isAdmin');

        notifyListeners();
        return true;
      }
      debugPrint('AuthProvider: Login retornou user null');
      return false;
    } catch (e) {
      debugPrint('AuthProvider: Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up user (Claim profile)
  Future<String?> signUp(String email, String password, String fullName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final error =
          await FirestoreService.instance.signUp(email, password, fullName);
      if (error == null) {
        // Success: User is logged in via Auth, refresh local state
        await checkLoginStatus();
        return null;
      }
      return error;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // MANAGING USERS (Admin Only)

  Future<List<UserModel>> getAllUsers() async {
    if (!isAdmin) return [];
    try {
      return await FirestoreService.instance.getAllUsers();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  Future<bool> createUser(UserModel user) async {
    if (!isAdmin) return false;
    try {
      // NOTE: This only creates the profile in Firestore.
      // The actual Auth account must be created separately or by the user.
      return await FirestoreService.instance.createUserProfile(user);
    } catch (e) {
      debugPrint('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    if (!isAdmin) return false;
    try {
      final success = await FirestoreService.instance.updateUser(user);
      // Update local state if updating self
      if (success && _currentUser?.id == user.id) {
        _currentUser = user;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    if (!isAdmin) return false;
    try {
      return await FirestoreService.instance.deleteUser(id);
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Enter visitor mode
  void enterVisitorMode() {
    _isVisitorMode = true;
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await FirestoreService.instance.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _isVisitorMode = false;
    notifyListeners();
  }
}
