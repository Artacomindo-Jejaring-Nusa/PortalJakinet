import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/customer_data.dart';
import '../models/technician_user.dart';

class LoginResult {
  final bool isTechnician;
  final TechnicianUser? technicianUser;
  final CustomerData? customerData;

  LoginResult({
    required this.isTechnician,
    this.technicianUser,
    this.customerData,
  });

  bool get isSuccess => isTechnician ? technicianUser != null : customerData != null;
}

class AuthService {
  final ApiService _apiService = ApiService();
  static const String _keySessionIdentifier = 'session_identifier';
  static const String _keySessionRole = 'session_role';

  // Perform login with Auto-Role Detection (Teknisi vs Pelanggan)
  Future<LoginResult> loginAutoDetect(String identifier) async {
    final cleaned = identifier.trim();
    if (cleaned.isEmpty) {
      return LoginResult(isTechnician: false);
    }

    // 1. Try Technician User Verification first
    final techUser = await _apiService.verifyTechnicianUser(cleaned);
    if (techUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionIdentifier, cleaned);
      await prefs.setString(_keySessionRole, 'technician');

      return LoginResult(isTechnician: true, technicianUser: techUser);
    }

    // 2. Try Customer Verification
    final customerData = await _apiService.verifyCustomer(cleaned);
    if (customerData != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionIdentifier, cleaned);
      await prefs.setString(_keySessionRole, 'customer');

      return LoginResult(isTechnician: false, customerData: customerData);
    }

    return LoginResult(isTechnician: false);
  }

  // Legacy customer login
  Future<CustomerData?> login(String identifier) async {
    final res = await loginAutoDetect(identifier);
    return res.customerData;
  }

  // Load existing session on startup
  Future<LoginResult> tryAutoLoginAutoDetect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final identifier = prefs.getString(_keySessionIdentifier);
      final role = prefs.getString(_keySessionRole);

      if (identifier == null || identifier.isEmpty) {
        return LoginResult(isTechnician: false);
      }

      if (role == 'technician') {
        final techUser = await _apiService.verifyTechnicianUser(identifier);
        if (techUser != null) {
          return LoginResult(isTechnician: true, technicianUser: techUser);
        }
      }

      final customerData = await _apiService.verifyCustomer(identifier);
      return LoginResult(isTechnician: false, customerData: customerData);
    } catch (e) {
      print('Auto login failed: $e');
      return LoginResult(isTechnician: false);
    }
  }

  Future<CustomerData?> tryAutoLogin() async {
    final res = await tryAutoLoginAutoDetect();
    return res.customerData;
  }

  // Perform logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionIdentifier);
    await prefs.remove(_keySessionRole);
  }
}
