import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/customer_data.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const String _keySessionIdentifier = 'session_identifier';

  // Perform login
  Future<CustomerData?> login(String identifier) async {
    final cleaned = identifier.trim();
    if (cleaned.isEmpty) return null;

    final customerData = await _apiService.verifyCustomer(cleaned);
    if (customerData != null) {
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySessionIdentifier, cleaned);
    }
    return customerData;
  }

  // Load existing session on startup
  Future<CustomerData?> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final identifier = prefs.getString(_keySessionIdentifier);

      if (identifier == null || identifier.isEmpty) {
        return null;
      }

      return await _apiService.verifyCustomer(identifier);
    } catch (e) {
      print('Auto login failed: $e');
      return null;
    }
  }

  // Perform logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionIdentifier);
  }
}
