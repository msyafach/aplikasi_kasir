import 'package:flutter/foundation.dart';
import 'db.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  Map<String, dynamic>? _currentUser;
  bool _isLoggedIn = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isKaryawan => _currentUser?['role'] == 'karyawan';
  String get userFullName => _currentUser?['full_name'] ?? 'Unknown';
  String get userRole => _currentUser?['role'] ?? 'unknown';

  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseService.instance.authenticateUser(username, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    if (!_isLoggedIn) return false;
    
    switch (permission) {
      case 'dashboard':
        return isAdmin;
      case 'inventory_full':
        return isAdmin;
      case 'inventory_view':
        return true; // Both admin and karyawan can view
      case 'pos':
        return true; // Both can use POS
      case 'history':
        return isAdmin; // Only admin can see full history
      case 'user_management':
        return isAdmin;
      default:
        return false;
    }
  }

  Future<void> initializeAuth() async {
    // Initialize default users if needed
    await DatabaseService.instance.seedDefaultUsersIfEmpty();
  }
}