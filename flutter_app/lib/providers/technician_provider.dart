import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/technician_user.dart';
import '../models/installation_task.dart';
import '../models/technician_ticket.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

class TechnicianProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  TechnicianUser? _technicianUser;
  List<InstallationTask> _installationQueue = [];
  List<TechnicianTicket> _tickets = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String _statusFilter = 'Semua';

  TechnicianUser? get technicianUser => _technicianUser;
  List<InstallationTask> get installationQueue => _installationQueue;
  List<TechnicianTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get statusFilter => _statusFilter;

    TechnicianProvider() {
    _init();

    // Listen for FCM notifications to automatically auto-refresh technician tasks
    FCMService().onMessageReceived = () {
      refreshData(showLoading: false);
    };
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('session_role');
      final identifier = prefs.getString('session_identifier');

      if (role == 'technician' && identifier != null && identifier.isNotEmpty) {
        final user = await _apiService.verifyTechnicianUser(identifier);
        if (user != null) {
          _technicianUser = user;
          await refreshData(showLoading: false);
        }
      }
    } catch (e) {
      // Ignore
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void setTechnicianUser(TechnicianUser user) {
    _technicianUser = user;
    _isInitialized = true;
    notifyListeners();
    refreshData(showLoading: false);
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  // Fetch installation queue and support tickets
  Future<void> refreshData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final futures = await Future.wait([
        _apiService.getInstallationQueue(),
        _apiService.getTechnicianTickets(),
      ]);

      _installationQueue = futures[0] as List<InstallationTask>;
      _tickets = futures[1] as List<TechnicianTicket>;
    } catch (e) {
      print('Error refreshing technician data: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Update ticket status
  Future<bool> updateTicketStatus(int ticketId, String status, String note) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.updateTicketStatus(ticketId, status, note);
    if (success) {
      // Local optimistic update
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = _tickets[index].copyWith(
          status: status,
          solution: note.isNotEmpty ? note : _tickets[index].solution,
        );
      }
      await refreshData(showLoading: false);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Update installation status
  Future<bool> updateInstallationStatus(int pelangganId, String status, String note) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.updateInstallationStatus(pelangganId, status, note);
    if (success) {
      final index = _installationQueue.indexWhere((t) => t.id == pelangganId);
      if (index != -1) {
        _installationQueue[index] = _installationQueue[index].copyWith(
          status: status,
          notes: note,
        );
      }
      await refreshData(showLoading: false);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Active badge counters
  int get activeTicketCount {
    return _tickets.where((t) {
      final st = t.status.toLowerCase();
      return !st.contains('closed') && !st.contains('resolved') && !st.contains('selesai') && !st.contains('batal');
    }).length;
  }

  int get activeInstallationCount {
    return _installationQueue.where((task) {
      final st = task.status.toLowerCase();
      return !st.contains('selesai') && !st.contains('installed') && !st.contains('terpasang');
    }).length;
  }

  // Filtered lists (Strictly hides Closed/Completed items by default in 'Semua' view)
  List<InstallationTask> get filteredInstallations {
    if (_statusFilter == 'Semua') {
      // By default show ONLY active pending/in-progress installations
      return _installationQueue.where((task) {
        final st = task.status.toLowerCase();
        return !st.contains('selesai') && !st.contains('installed') && !st.contains('terpasang');
      }).toList();
    }
    return _installationQueue.where((task) {
      final st = task.status.toLowerCase();
      if (_statusFilter == 'Pending') return st.contains('pending') || st.contains('baru') || st.contains('belum');
      if (_statusFilter == 'On Progress') return st.contains('proses') || st.contains('progress') || st.contains('dalam');
      if (_statusFilter == 'Selesai') return st.contains('selesai') || st.contains('installed') || st.contains('terpasang') || st.contains('aktif');
      return true;
    }).toList();
  }

  List<TechnicianTicket> get filteredTickets {
    if (_statusFilter == 'Semua') {
      // By default show ONLY Open / In-Progress tickets, HIDE Closed tickets!
      return _tickets.where((ticket) {
        final st = ticket.status.toLowerCase();
        return !st.contains('closed') && !st.contains('resolved') && !st.contains('selesai') && !st.contains('batal');
      }).toList();
    }
    return _tickets.where((ticket) {
      final st = ticket.status.toLowerCase();
      if (_statusFilter == 'Pending') return st.contains('open') || st.contains('pending') || st.contains('baru');
      if (_statusFilter == 'On Progress') return st.contains('progress') || st.contains('in_progress') || st.contains('proses');
      if (_statusFilter == 'Selesai') return st.contains('resolved') || st.contains('closed') || st.contains('selesai') || st.contains('batal');
      return true;
    }).toList();
  }

  void clear() {
    _technicianUser = null;
    _installationQueue = [];
    _tickets = [];
    _isLoading = false;
    notifyListeners();
  }
}


