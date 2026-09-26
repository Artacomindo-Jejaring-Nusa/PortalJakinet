import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/customer_data.dart';
import '../models/invoice.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../config/constants.dart';

class CustomerProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  CustomerData? _customerData;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  CustomerData? get customerData => _customerData;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  CustomerProvider() {
    _init();
    
    // Listen for FCM notification arrival to automatically auto-refresh data
    FCMService().onMessageReceived = () {
      print('🔄 FCM Notification received -> Auto refreshing dashboard data in real-time...');
      refresh(showLoading: false);
    };
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('session_role');
      final identifier = prefs.getString('session_identifier');

      if (role == 'customer' && identifier != null && identifier.isNotEmpty) {
        _customerData = await _apiService.verifyCustomer(identifier);
        if (_customerData != null) {
          _registerFCMToken();
        }
      }
    } catch (e) {
      _error = 'Auto-login failed: $e';
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register FCM Token helper
  Future<void> _registerFCMToken() async {
    if (_customerData == null) return;
    final phone = _customerData!.pelanggan.noTelp;
    final email = _customerData!.pelanggan.email;
    final identifier = phone.isNotEmpty ? phone : email;

    if (identifier.isNotEmpty) {
      await FCMService().sendTokenToBackend(identifier: identifier);
    }
  }

  // Auto-detect role login handler
  Future<LoginResult> loginAutoDetect(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _authService.loginAutoDetect(identifier);
      if (res.isTechnician && res.technicianUser != null) {
        _isLoading = false;
        notifyListeners();
        return res;
      } else if (res.customerData != null) {
        _customerData = res.customerData;
        _registerFCMToken();
        _isLoading = false;
        notifyListeners();
        return res;
      } else {
        _error = 'Data tidak ditemukan. Pastikan email atau nomor WhatsApp terdaftar.';
        _isLoading = false;
        notifyListeners();
        return res;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan jaringan. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return LoginResult(isTechnician: false);
    }
  }

  // Legacy Customer login handler
  Future<bool> login(String identifier) async {
    final res = await loginAutoDetect(identifier);
    return res.isSuccess && !res.isTechnician;
  }

  // Logout handler
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _customerData = null;
    _isLoading = false;
    notifyListeners();
  }

  // Refresh handler (supports silent background refresh on FCM notification)
  Future<void> refresh({bool showLoading = true}) async {
    if (_customerData == null) return;
    
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final phone = _customerData!.pelanggan.noTelp;
      final email = _customerData!.pelanggan.email;
      final customerId = _customerData!.pelanggan.id;
      
      CustomerData? refreshed;
      if (email.isNotEmpty) {
        refreshed = await _apiService.getCustomerByEmail(email);
      } else if (phone.isNotEmpty) {
        refreshed = await _apiService.getCustomerByPhone(phone);
      }
      
      refreshed ??= await _apiService.getCustomerDirectLookup(customerId.toString());

      if (refreshed != null) {
        _customerData = refreshed;
      }
    } catch (e) {
      print('Refresh failed: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Helper properties
  bool get isJelantik {
    if (_customerData == null) return false;
    final brandName = _customerData!.pelanggan.hargaLayanan?.brand.toUpperCase() ?? '';
    final brandId = _customerData!.pelanggan.idBrand.toLowerCase();
    return brandName.contains('JELANTIK') || brandId == 'ajn-02' || brandId == 'ajn-03';
  }

  String get brandKey => isJelantik ? 'jelantik' : 'jakinet';
  String get brandTitle => isJelantik ? 'Portal Jelantik' : 'Portal Jakinet';
  String get brandLogo => isJelantik ? 'assets/images/icons/jelantik.webp' : 'assets/images/icons/jakinet.png';
  String get brandSupportText => isJelantik ? 'Pesan dari Jelantik akan muncul di sini' : 'Pesan dari Jakinet akan muncul di sini';
  String get brandWhatsapp => isJelantik ? AppConstants.jelantikWhatsapp : AppConstants.jakinetWhatsapp;

  String get speed {
    if (_customerData == null) return '10';
    final layananName = _customerData!.pelanggan.layanan.isEmpty
        ? 'Internet 10 Mbps'
        : _customerData!.pelanggan.layanan;
    final match = RegExp(r'(\d+)\s*Mbps', caseSensitive: false).firstMatch(layananName);
    return match != null ? match.group(1) ?? '10' : '10';
  }

  String get customerId {
    if (_customerData == null) return '-';
    final p = _customerData!.pelanggan;
    if (p.customerId.isNotEmpty) {
      return p.customerId;
    }
    return p.id.toString();
  }

  String get subscriptionStatus {
    if (_customerData == null) return 'Aktif';
    final status = _customerData!.langganan?.status ?? 'Aktif';
    if (status.toLowerCase().contains('suspend')) return 'Suspended';
    if (status.toLowerCase().contains('non-aktif') || status.toLowerCase() == 'non aktif') return 'Non-Aktif';
    return status;
  }

  bool get isActive => subscriptionStatus.toLowerCase() == 'aktif';

  List<Invoice> get allInvoices {
    if (_customerData == null) return [];
    return _customerData!.invoices.where((inv) {
      final status = inv.statusInvoice.toLowerCase();
      return !status.contains('batal') && !status.contains('cancel');
    }).toList();
  }

  List<Invoice> get activeInvoices => allInvoices;

  Invoice? get currentActiveBill {
    final unpaid = allInvoices.where((inv) {
      final status = inv.statusInvoice.toLowerCase();
      final isPaid = status == 'lunas' || status.contains('lunas') || status.contains('paid');
      final isExpired = status.contains('expired') || status.contains('kadaluarsa') || status.contains('kadaluwarsa');
      final isCancelled = status.contains('batal') || status.contains('cancel');
      return !isPaid && !isExpired && !isCancelled;
    }).toList();
    if (unpaid.isEmpty) return null;
    unpaid.sort((a, b) {
      if (a.tglJatuhTempo.isEmpty) return 1;
      if (b.tglJatuhTempo.isEmpty) return -1;
      return b.tglJatuhTempo.compareTo(a.tglJatuhTempo);
    });
    return unpaid.first;
  }

  int get totalUnpaid {
    return currentActiveBill?.totalHarga ?? 0;
  }

  int get unpaidCount {
    return currentActiveBill != null ? 1 : 0;
  }

  Invoice? get nextDueInvoice => currentActiveBill;
}

