import 'package:flutter/material.dart';
import '../models/customer_data.dart';
import '../models/invoice.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/constants.dart';

class CustomerProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  CustomerData? _customerData;
  bool _isLoading = false;
  String? _error;

  CustomerData? get customerData => _customerData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customerData = await _authService.tryAutoLogin();
    } catch (e) {
      _error = 'Auto-login failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login handler
  Future<bool> login(String identifier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(identifier);
      if (result != null) {
        _customerData = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Data tidak ditemukan. Pastikan email atau nomor telepon terdaftar.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan jaringan. Silakan coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

  // Refresh handler
  Future<void> refresh() async {
    if (_customerData == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final phone = _customerData!.pelanggan.noTelp;
      final email = _customerData!.pelanggan.email;
      
      CustomerData? refreshed;
      if (email.isNotEmpty) {
        refreshed = await _apiService.getCustomerByEmail(email);
      } else if (phone.isNotEmpty) {
        refreshed = await _apiService.getCustomerByPhone(phone);
      }

      if (refreshed != null) {
        _customerData = refreshed;
      }
    } catch (e) {
      print('Refresh failed: $e');
    } finally {
      _isLoading = false;
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

  List<Invoice> get activeInvoices {
    if (_customerData == null) return [];
    return _customerData!.invoices.where((inv) => !inv.isExpired()).toList();
  }

  Invoice? get currentActiveBill {
    final unpaid = activeInvoices.where((inv) => inv.statusInvoice != 'Lunas').toList();
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
