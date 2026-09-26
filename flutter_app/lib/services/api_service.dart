import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/pelanggan.dart';
import '../models/langganan.dart';
import '../models/invoice.dart';
import '../models/customer_data.dart';
import '../models/technician_user.dart';
import '../models/installation_task.dart';
import '../models/technician_ticket.dart';

class ApiService {
  String? _adminToken;
  DateTime? _tokenExpiry;

  // Get admin access token
  Future<String> _getAdminToken() async {
    if (AppConstants.apiKey.isNotEmpty) {
      return AppConstants.apiKey;
    }

    final now = DateTime.now();

    if (_adminToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(now.add(const Duration(minutes: 5)))) {
      return _adminToken!;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': AppConstants.apiUsername,
          'password': AppConstants.apiPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Authentication failed: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      _adminToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = now.add(Duration(seconds: expiresIn));

      return _adminToken!;
    } catch (e) {
      print('Error getting admin token: $e');
      rethrow;
    }
  }

  // Helper search pelanggan using search endpoint
  Future<List<Pelanggan>> _searchPelanggan(String query) async {
    try {
      final token = await _getAdminToken();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/pelanggan?search=${Uri.encodeComponent(query)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final result = json.decode(response.body);
      final list = result['data'] as List?;
      if (list == null) return [];

      return list.map((p) => Pelanggan.fromJson(p)).toList();
    } catch (e) {
      print('Error searching pelanggan: $e');
      return [];
    }
  }

  // Get Customer data by email
  Future<CustomerData?> getCustomerByEmail(String email) async {
    try {
      final results = await _searchPelanggan(email);
      final matched = results.firstWhere(
        (p) => p.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Customer not found'),
      );

      final data = await _fetchRelatedData(matched);
      return data;
    } catch (e) {
      print('Error in getCustomerByEmail: $e');
      return null;
    }
  }

  // Direct Fast Customer Lookup by identifier (email, phone, customer ID)
  Future<CustomerData?> getCustomerDirectLookup(String identifier) async {
    try {
      final token = await _getAdminToken();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/portal/customer/lookup?identifier=${Uri.encodeComponent(identifier)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': token,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final result = json.decode(response.body);
      if (result != null && result['data'] != null && result['data']['pelanggan'] != null) {
        final pelanggan = Pelanggan.fromJson(result['data']['pelanggan']);
        
        Langganan? langganan;
        if (result['data']['langganan'] != null) {
          langganan = Langganan.fromJson(result['data']['langganan']);
        }

        List<Invoice> invoices = [];
        if (result['data']['invoices'] != null && result['data']['invoices'] is List) {
          invoices = (result['data']['invoices'] as List)
              .map((inv) => Invoice.fromJson(inv))
              .toList();
        }

        if (langganan == null || invoices.isEmpty) {
          final related = await _fetchRelatedData(pelanggan);
          langganan ??= related.langganan;
          if (invoices.isEmpty) {
            invoices = related.invoices;
          }
        }

        return CustomerData(
          pelanggan: pelanggan,
          langganan: langganan,
          invoices: invoices,
        );
      }
      return null;
    } catch (e) {
      print('Error in getCustomerDirectLookup: $e');
      return null;
    }
  }

  // Normalize phone number for standard comparison
  String _normalizePhone(String numStr) {
    var cleaned = numStr.replaceAll(RegExp(r'[-\s]'), '');
    if (cleaned.startsWith('+62')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('62')) {
      cleaned = '0${cleaned.substring(2)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '0$cleaned';
    }
    return cleaned;
  }

  // Get Customer data by phone
  Future<CustomerData?> getCustomerByPhone(String phone) async {
    try {
      // 1. Try search using full input phone (e.g. 08986937819)
      var results = await _searchPelanggan(phone);

      // 2. Fallback to core phone search (e.g. 8986937819)
      if (results.isEmpty) {
        var corePhone = phone.replaceAll(RegExp(r'[-\s]'), '');
        if (corePhone.startsWith('+62')) {
          corePhone = corePhone.substring(3);
        } else if (corePhone.startsWith('62')) {
          corePhone = corePhone.substring(2);
        } else if (corePhone.startsWith('0')) {
          corePhone = corePhone.substring(1);
        }
        results = await _searchPelanggan(corePhone);
      }

      final targetNormalized = _normalizePhone(phone);

      final matched = results.firstWhere(
        (p) => p.noTelp.isNotEmpty && _normalizePhone(p.noTelp) == targetNormalized,
        orElse: () => throw Exception('Customer not found'),
      );

      final data = await _fetchRelatedData(matched);
      return data;
    } catch (e) {
      print('Error in getCustomerByPhone: $e');
      return null;
    }
  }

  // Fetch subscription by customer ID
  Future<Langganan?> getLanggananByPelangganId(int pelangganId) async {
    try {
      final token = await _getAdminToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/langganan?pelanggan_id=$pelangganId&_t=$timestamp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final rawData = data['data'] ?? data;
      if (rawData is List) {
        for (var item in rawData) {
          final itemPelangganId = item['pelanggan_id'] ?? item['id_pelanggan'];
          if (itemPelangganId.toString() == pelangganId.toString()) {
            return Langganan.fromJson(item);
          }
        }
        return null;
      }
      return Langganan.fromJson(rawData);
    } catch (e) {
      print('Error fetching langganan: $e');
      return null;
    }
  }

  // Fetch invoices by customer ID with multiple endpoint fallbacks
  Future<List<Invoice>> getInvoicesByPelangganId(int pelangganId, String customerName) async {
    try {
      final token = await _getAdminToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final endpoints = ['/invoices', '/tagihan', '/invoice'];
      List<dynamic> rawInvoices = [];

      for (var endpoint in endpoints) {
        final searchParams = Uri.encodeQueryComponent('search') +
            '=${Uri.encodeQueryComponent(pelangganId.toString())}' +
            '&${Uri.encodeQueryComponent('pelanggan_id')}=${Uri.encodeQueryComponent(pelangganId.toString())}' +
            '&${Uri.encodeQueryComponent('id_pelanggan')}=${Uri.encodeQueryComponent(pelangganId.toString())}' +
            '&limit=100&_t=$timestamp';

        final response = await http.get(
          Uri.parse('${AppConstants.apiBaseUrl}$endpoint?$searchParams'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final list = _extractArray(data);
          if (list.isNotEmpty) {
            rawInvoices = list;
            break;
          }
        }

        // Search by Name fallback
        if (customerName.isNotEmpty) {
          final nameParams = 'search=${Uri.encodeQueryComponent(customerName)}&limit=100&_t=$timestamp';
          final nameResponse = await http.get(
            Uri.parse('${AppConstants.apiBaseUrl}$endpoint?$nameParams'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (nameResponse.statusCode == 200) {
            final data = json.decode(nameResponse.body);
            final list = _extractArray(data);
            if (list.isNotEmpty) {
              rawInvoices = list;
              break;
            }
          }
        }
      }

      final invoices = <Invoice>[];
      for (var inv in rawInvoices) {
        final invPelangganId = inv['pelanggan_id'] ?? inv['id_pelanggan'] ?? inv['customer_id'];
        if (invPelangganId != null && invPelangganId.toString() == pelangganId.toString()) {
          invoices.add(Invoice.fromJson(inv));
          continue;
        }

        final invName = inv['nama_pelanggan'] ?? inv['pelanggan']?['nama'] ?? inv['customer_name'] ?? inv['nama'];
        if (invName != null &&
            invName.toString().toLowerCase().contains(customerName.toLowerCase())) {
          invoices.add(Invoice.fromJson(inv));
        }
      }

      return invoices;
    } catch (e) {
      print('Error fetching invoices: $e');
      return [];
    }
  }

  List<dynamic> _extractArray(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      if (data['data'] is List) return data['data'];
      if (data['invoices'] is List) return data['invoices'];
      if (data['tagihan'] is List) return data['tagihan'];
      
      for (var val in data.values) {
        if (val is List) return val;
      }
    }
    return [];
  }

  // Load related details in parallel
  Future<CustomerData> _fetchRelatedData(Pelanggan pelanggan) async {
    final futures = await Future.wait([
      getLanggananByPelangganId(pelanggan.id),
      getInvoicesByPelangganId(pelanggan.id, pelanggan.nama),
    ]);

    return CustomerData(
      pelanggan: pelanggan,
      langganan: futures[0] as Langganan?,
      invoices: futures[1] as List<Invoice>,
    );
  }

  // Validate Customer credential (email, phone, customer ID, KTP)
  Future<CustomerData?> verifyCustomer(String identifier) async {
    // 1. Try direct ultra-fast lookup first (matches phone, email, customer ID)
    final directData = await getCustomerDirectLookup(identifier);
    if (directData != null) {
      return directData;
    }

    // 2. Fallback lookup by email or phone
    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);
    if (isEmail) {
      return getCustomerByEmail(identifier);
    } else {
      return getCustomerByPhone(identifier);
    }
  }

  // ── TECHNICIAN ENDPOINTS ──────────────────────────────────────────

  // Check if identifier belongs to a Technician user (Role: Teknisi)
  Future<TechnicianUser?> verifyTechnicianUser(String identifier) async {
    try {
      final token = await _getAdminToken();
      final normalizedId = _normalizePhone(identifier);
      final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': token,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final list = _extractArray(body);

        for (var item in list) {
          if (item is Map<String, dynamic>) {
            final itemEmail = (item['email'] ?? '').toString().toLowerCase();
            final rawPhone = (item['phone_no'] ?? item['whatsapp'] ?? item['no_telp'] ?? item['phone'] ?? '').toString();
            final itemPhone = _normalizePhone(rawPhone);

            String roleName = '';
            if (item['role'] != null) {
              if (item['role'] is Map) {
                roleName = (item['role']['name'] ?? item['role']['nama'] ?? '').toString().toLowerCase();
              } else {
                roleName = item['role'].toString().toLowerCase();
              }
            }

            final matchIdent = (isEmail && itemEmail == identifier.toLowerCase()) ||
                (!isEmail && itemPhone == normalizedId) ||
                (item['id'].toString() == identifier);

            if (matchIdent) {
              if (roleName.contains('teknisi') || roleName.contains('technician') || roleName.contains('admin') || roleName.contains('staff') || roleName.isNotEmpty) {
                return TechnicianUser.fromJson(item);
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error in verifyTechnicianUser: $e');
      return null;
    }
  }

  // Fetch New Installation Queue List
  Future<List<InstallationTask>> getInstallationQueue() async {
    try {
      final token = await _getAdminToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final endpoints = [
        '/pelanggan?limit=100&_t=$timestamp',
      ];

      List<InstallationTask> tasks = [];
      for (var ep in endpoints) {
        final response = await http.get(
          Uri.parse('${AppConstants.apiBaseUrl}$ep'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final list = _extractArray(data);
          if (list.isNotEmpty) {
            tasks = list.map((item) => InstallationTask.fromJson(item)).toList();
            break;
          }
        }
      }

      return tasks;
    } catch (e) {
      print('Error fetching installation queue: $e');
      return [];
    }
  }

  // Fetch Technician Support Tickets List
  Future<List<TechnicianTicket>> getTechnicianTickets() async {
    try {
      final token = await _getAdminToken();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final endpoints = [
        '/trouble-tickets?limit=100&_t=$timestamp',
      ];

      List<TechnicianTicket> tickets = [];
      for (var ep in endpoints) {
        final response = await http.get(
          Uri.parse('${AppConstants.apiBaseUrl}$ep'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final list = _extractArray(data);
          if (list.isNotEmpty) {
            tickets = list.map((item) => TechnicianTicket.fromJson(item)).toList();
            break;
          }
        }
      }

      return tickets;
    } catch (e) {
      print('Error fetching technician tickets: $e');
      return [];
    }
  }

  // Update Ticket Status & Add Action Note
  Future<bool> updateTicketStatus(int ticketId, String status, String note) async {
    try {
      final token = await _getAdminToken();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/trouble-tickets/$ticketId/action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'notes': note,
          'action_type': 'Update Status oleh Teknisi',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating ticket status: $e');
      return false;
    }
  }

  // Update Installation Task Status
  Future<bool> updateInstallationStatus(int pelangganId, String status, String note) async {
    try {
      final token = await _getAdminToken();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/pelanggan/$pelangganId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status_instalasi': status,
          'notes': note,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updating installation status: $e');
      return false;
    }
  }
}

