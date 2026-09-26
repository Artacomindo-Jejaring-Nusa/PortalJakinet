import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/chat_message.dart';
import '../services/chat_socket_service.dart';
import '../services/fcm_service.dart';

class ChatFaqItem {
  final String id;
  final String title;
  final String shortTitle;
  final String answer;

  const ChatFaqItem({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.answer,
  });
}

class ChatProvider extends ChangeNotifier {
  final ChatSocketService _socketService = ChatSocketService();

  List<ChatMessage> _messages = [];
  bool _isLoadingHistory = false;
  bool _isUploadingImage = false;
  bool _isConnected = false;
  bool _isOtherTyping = false;
  bool _isChatTabActive = false;
  bool _isConnectedToAgent = false;
  int? _roomId;
  int? _pelangganId;
  String? _brand;
  String? _name;

  Timer? _pollingTimer;
  Timer? _typingTimer;
  Timer? _typingThrottleTimer;
  bool _isSendingTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isUploadingImage => _isUploadingImage;
  bool get isConnected => _isConnected;
  bool get isOtherTyping => _isOtherTyping;
  bool get isChatTabActive => _isChatTabActive;
  bool get isConnectedToAgent => _isConnectedToAgent;
  int? get roomId => _roomId;

  // Daftar FAQ & Template Pertanyaan Berulang
  static const List<ChatFaqItem> faqList = [
    ChatFaqItem(
      id: '1.1',
      title: '1.1 📡 Kendala WiFi Lambat / Sinyal Lemah',
      shortTitle: 'WiFi Lambat',
      answer: 'Berikut langkah cepat mengatasi koneksi lambat:\n\n'
          '1. Matikan modem ONT dengan mencabut adaptor listrik selama 10-30 detik lalu colokkan kembali.\n'
          '2. Pastikan lampu indikator PON menyala hijau stabil (tidak berkedip) dan lampu LOS mati.\n'
          '3. Hindari sekat tembok tebal atau perangkat elektronik lain yang menghalangi sinyal Wi-Fi.\n'
          '4. Coba putuskan dan sambungkan ulang (Forget Network) jaringan Wi-Fi di HP Anda.',
    ),
    ChatFaqItem(
      id: '1.2',
      title: '1.2 🔴 Lampu Indikator LOS Menyala Merah',
      shortTitle: 'Lampu LOS Merah',
      answer: 'Lampu indikator LOS merah menandakan kabel fiber optik tidak menerima sinyal cahaya dari ODP:\n\n'
          '• Periksa kabel optik (kabel kuning/hitam kecil) di belakang modem, pastikan konektor tertancap rapat dan kabel tidak tertekuk tajam/terjepit.\n'
          '• Jika kabel dalam kondisi baik namun lampu tetap merah, kemungkinan ada gangguan kabel luar atau pemeliharaan jaringan.\n'
          '• Silakan tekan "Hubungkan ke CS" untuk dijadwalkan pengecekan oleh Teknisi.',
    ),
    ChatFaqItem(
      id: '1.3',
      title: '1.3 💳 Info Tagihan & Cara Pembayaran',
      shortTitle: 'Info Tagihan & Bayar',
      answer: 'Untuk rincian tagihan internet Anda:\n\n'
          '• Buka menu "Home" atau "History" di aplikasi ini untuk melihat invoice aktif.\n'
          '• Pembayaran dapat dilakukan via Virtual Account (BCA, Mandiri, BRI, BNI) atau scan QRIS.\n'
          '• Setelah pembayaran berhasil, status langganan akan otomatis tersinkronisasi dalam 1-5 menit.',
    ),
    ChatFaqItem(
      id: '1.4',
      title: '1.4 🔄 Panduan Restart / Reset Modem yang Aman',
      shortTitle: 'Restart / Reset Modem',
      answer: '⚠️ PERHATIAN PENTING:\n\n'
          '• Cukup cabut adaptor power listrik modem selama 30 detik lalu pasang kembali.\n'
          '• HINDARI menusuk lubang kecil berlabel "RESET" di belakang modem! Menusuk tombol reset akan menghapus username & password internet (PPPoE) sehingga modem tidak bisa terhubung ke server dan harus disetting ulang oleh teknisi.',
    ),
    ChatFaqItem(
      id: '1.5',
      title: '1.5 ⏱️ Jam Operasional CS & Kunjungan Teknisi',
      shortTitle: 'Jam Operasional',
      answer: '• Layanan Customer Support (Chat & WhatsApp) beroperasi setiap hari: 08:00 - 22:00 WIB.\n'
          '• Layanan Kunjungan Teknisi Lapangan (perbaikan fisik & pemasangan baru): Senin - Minggu pukul 08:30 - 17:00 WIB.',
    ),
  ];

  ChatProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketService.onConnectionChanged = (connected) {
      _isConnected = connected;
      notifyListeners();
    };

    _socketService.onRoomConnected = (roomId) {
      _roomId = roomId;
      notifyListeners();
    };

    _socketService.onAckSent = (tempId, messageId, status) {
      final index = _messages.indexWhere((m) => m.tempId == tempId);
      if (index != -1) {
        final old = _messages[index];
        _messages[index] = ChatMessage(
          id: messageId > 0 ? messageId : old.id,
          roomId: old.roomId,
          senderType: old.senderType,
          senderName: old.senderName,
          message: old.message,
          messageType: old.messageType,
          attachmentUrl: old.attachmentUrl,
          status: status, // Ceklis 1 Abu-abu
          createdAt: old.createdAt,
          tempId: tempId,
        );
        notifyListeners();
      }
    };

    _socketService.onStatusUpdate = (msgId, tempId, status) {
      int index = -1;
      if (msgId > 0) {
        index = _messages.indexWhere((m) => m.id == msgId);
      }
      if (index == -1 && tempId != null && tempId.isNotEmpty) {
        index = _messages.indexWhere((m) => m.tempId == tempId);
      }

      if (index != -1) {
        final old = _messages[index];
        _messages[index] = ChatMessage(
          id: old.id,
          roomId: old.roomId,
          senderType: old.senderType,
          senderName: old.senderName,
          message: old.message,
          messageType: old.messageType,
          attachmentUrl: old.attachmentUrl,
          status: status, // Ceklis 2 Abu-abu / Ceklis 2 Biru
          createdAt: old.createdAt,
          tempId: old.tempId,
        );
        notifyListeners();
      }
    };

    _socketService.onRoomRead = (roomId) {
      bool updated = false;
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].isMe && _messages[i].status != 'read') {
          final m = _messages[i];
          _messages[i] = ChatMessage(
            id: m.id,
            roomId: m.roomId,
            senderType: m.senderType,
            senderName: m.senderName,
            message: m.message,
            messageType: m.messageType,
            attachmentUrl: m.attachmentUrl,
            status: 'read', // Ceklis 2 Biru
            createdAt: m.createdAt,
            tempId: m.tempId,
          );
          updated = true;
        }
      }
      if (updated) {
        notifyListeners();
      }
    };

    _socketService.onNewMessage = (newMsg) {
      // Jika ada balasan dari admin/CS, tandai bahwa user sudah terhubung ke agen manusia
      if (!newMsg.isMe) {
        _isConnectedToAgent = true;
      }

      final existingIndex = _messages.indexWhere((m) =>
          (newMsg.id != null && m.id == newMsg.id) ||
          (newMsg.tempId != null && newMsg.tempId!.isNotEmpty && m.tempId == newMsg.tempId));

      if (existingIndex == -1) {
        _messages.add(newMsg);
        notifyListeners();

        if (_isChatTabActive && !newMsg.isMe && _roomId != null) {
          markAsRead();
        } else if (!_isChatTabActive && !newMsg.isMe) {
          FCMService().showChatNotification(
            title: newMsg.senderName.isNotEmpty ? newMsg.senderName : 'Customer Support',
            body: newMsg.message.isNotEmpty ? newMsg.message : 'Mengirim foto',
            data: {'type': 'chat', 'room_id': newMsg.roomId.toString()},
          );
        }
      } else {
        _messages[existingIndex] = newMsg;
        notifyListeners();
      }
    };

    _socketService.onTyping = (isTyping) {
      _isOtherTyping = isTyping;
      notifyListeners();

      _typingTimer?.cancel();
      if (isTyping) {
        _typingTimer = Timer(const Duration(seconds: 3), () {
          _isOtherTyping = false;
          notifyListeners();
        });
      }
    };
  }

  void setChatTabActive(bool active) {
    _isChatTabActive = active;
    _pollingTimer?.cancel();
    if (active) {
      if (_roomId != null && _hasUnreadMessages()) {
        markAsRead();
      }
      _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_isChatTabActive && _roomId != null && !_isConnected) {
          fetchHistory(silent: true);
        }
      });
    }
  }

  bool _hasUnreadMessages() {
    return _messages.any((m) => !m.isMe && m.status != 'read');
  }

  Future<void> initChat({
    required int pelangganId,
    required String brand,
    required String name,
  }) async {
    if (_pelangganId == pelangganId && _isConnected) {
      return;
    }

    _pelangganId = pelangganId;
    _brand = brand;
    _name = name;

    // 1. Fetch existing room & history via REST first (mencegah race condition)
    await fetchHistory();

    // 2. Connect WebSocket setelah room dipastikan ada/diketahui
    _socketService.connect(
      pelangganId: pelangganId,
      brand: brand,
      name: name,
    );
  }

  Future<void> fetchHistory({bool silent = false}) async {
    if (_pelangganId == null) return;

    if (!silent) {
      _isLoadingHistory = true;
      notifyListeners();
    }

    try {
      // Dapatkan room ID jika belum ada
      if (_roomId == null) {
        final roomUri = Uri.parse(
          '${AppConstants.apiBaseUrl}/chat/customer/room?pelanggan_id=$_pelangganId&brand=${_brand ?? "Jakinet"}',
        );
        final roomRes = await http.get(roomUri);
        if (roomRes.statusCode == 200) {
          final roomJson = json.decode(roomRes.body);
          if (roomJson['data'] != null && roomJson['data']['id'] != null) {
            _roomId = int.tryParse(roomJson['data']['id'].toString());
          }
        }
      }

      // Ambil riwayat pesan jika room ID sudah ada
      if (_roomId != null) {
        final msgUri = Uri.parse('${AppConstants.apiBaseUrl}/chat/messages/$_roomId?limit=100&offset=0');
        final msgRes = await http.get(msgUri);
        if (msgRes.statusCode == 200) {
          final msgJson = json.decode(msgRes.body);
          if (msgJson['data'] is List) {
            final List<ChatMessage> loaded = (msgJson['data'] as List)
                .map((item) => ChatMessage.fromJson(item))
                .toList();

            final pendingMessages = _messages.where((m) => m.isPending).toList();
            _messages = loaded;
            for (final pending in pendingMessages) {
              final exists = _messages.any((m) => m.tempId == pending.tempId);
              if (!exists) {
                _messages.add(pending);
              }
            }

            // Periksa apakah pernah ada balasan dari admin
            _isConnectedToAgent = _messages.any((m) => m.senderType == 'admin');

            notifyListeners();

            if (_isChatTabActive && _hasUnreadMessages()) {
              markAsRead();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatProvider] Fetch history error: $e');
    } finally {
      if (!silent) {
        _isLoadingHistory = false;
        notifyListeners();
      }
    }
  }

  // Kirim pesan manual biasa
  void sendMessage(String text, {String type = 'text', String? attachmentUrl}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty && attachmentUrl == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final localMsg = ChatMessage(
      roomId: _roomId ?? 0,
      senderType: 'customer',
      senderName: _name ?? 'Customer',
      message: cleanText,
      messageType: type,
      attachmentUrl: attachmentUrl,
      status: 'pending',
      createdAt: DateTime.now(),
      tempId: tempId,
    );

    _messages.add(localMsg);
    notifyListeners();

    _socketService.sendMessage(cleanText, tempId, type: type, attachmentUrl: attachmentUrl);
  }

  // 1. Eksekusi Menu Otomatis: Bantuan Cepat / FAQ Template
  void sendFaqAnswer(ChatFaqItem faq) {
    // 1. Tampilkan pertanyaan pelanggan di chat
    sendMessage(faq.title);

    // 2. Tampilkan balasan otomatis dari Virtual Assistant
    Future.delayed(const Duration(milliseconds: 350), () {
      final assistantMsg = ChatMessage(
        roomId: _roomId ?? 0,
        senderType: 'system',
        senderName: 'Virtual Assistant',
        message: '${faq.answer}\n\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            '💡 Apakah panduan ini membantu?\n'
            'Jika masih mengalami kendala, Anda dapat menekan opsi "2. Hubungkan ke CS" di bawah.',
        messageType: 'text',
        status: 'delivered',
        createdAt: DateTime.now(),
        tempId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      );

      _messages.add(assistantMsg);
      notifyListeners();
    });
  }

  // 2. Eksekusi Menu Otomatis: Hubungkan ke Agent CS
  void requestConnectToAgent() {
    _isConnectedToAgent = true;

    // 1. Kirim pesan permohonan dari pelanggan (akan masuk ke server backend & dilihat CS)
    sendMessage('2. Hubungkan saya dengan Customer Support (CS)');

    // 2. Balasan sistem langsung memberitahukan bahwa sesi telah dialihkan ke antrian CS
    Future.delayed(const Duration(milliseconds: 300), () {
      final systemMsg = ChatMessage(
        roomId: _roomId ?? 0,
        senderType: 'system',
        senderName: 'Virtual Assistant',
        message: 'Permintaan Anda telah diterima! 👨‍💼\n\n'
            'Anda sedang dihubungkan dengan Customer Support yang bertugas. '
            'Mohon tunggu sebentar, pesan Anda akan segera ditanggapi oleh tim kami.',
        messageType: 'text',
        status: 'delivered',
        createdAt: DateTime.now(),
        tempId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      );

      _messages.add(systemMsg);
      notifyListeners();
    });
  }

  // Handle input teks angka 1 atau 2 dari user
  bool handleQuickInput(String text) {
    final cleaned = text.trim().toLowerCase();
    if (cleaned == '1' || cleaned == 'bantuan' || cleaned == 'faq') {
      _showFaqMenu();
      return true;
    } else if (cleaned == '2' || cleaned == 'cs' || cleaned == 'agent' || cleaned == 'operator') {
      requestConnectToAgent();
      return true;
    } else if (cleaned == '1.1') {
      sendFaqAnswer(faqList[0]);
      return true;
    } else if (cleaned == '1.2') {
      sendFaqAnswer(faqList[1]);
      return true;
    } else if (cleaned == '1.3') {
      sendFaqAnswer(faqList[2]);
      return true;
    } else if (cleaned == '1.4') {
      sendFaqAnswer(faqList[3]);
      return true;
    } else if (cleaned == '1.5') {
      sendFaqAnswer(faqList[4]);
      return true;
    }
    return false;
  }

  void _showFaqMenu() {
    sendMessage('1. Bantuan Cepat / FAQ');

    Future.delayed(const Duration(milliseconds: 300), () {
      final botMenu = ChatMessage(
        roomId: _roomId ?? 0,
        senderType: 'system',
        senderName: 'Virtual Assistant',
        message: 'Silakan pilih topik bantuan yang Anda butuhkan:\n\n'
            '1.1 📡 WiFi Lambat / Putus-Putus\n'
            '1.2 🔴 Lampu LOS Merah / Kabel Putus\n'
            '1.3 💳 Info Tagihan & Cara Bayar\n'
            '1.4 🔄 Cara Restart Modem yang Aman\n'
            '1.5 ⏱️ Jam Operasional CS & Teknisi\n\n'
            'Ketik angka opsi (misal 1.1) atau tekan tombol menu di bawah.',
        messageType: 'text',
        status: 'delivered',
        createdAt: DateTime.now(),
        tempId: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      );

      _messages.add(botMenu);
      notifyListeners();
    });
  }

  Future<bool> uploadAndSendImage(File imageFile, {String caption = ''}) async {
    _isUploadingImage = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/chat/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fileUrl = data['file_url'] as String?;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          sendMessage(caption, type: 'image', attachmentUrl: fileUrl);
          return true;
        }
      } else {
        debugPrint('[ChatProvider] Upload image failed with status: ${response.statusCode}, body: ${response.body}');
      }
      return false;
    } catch (e) {
      debugPrint('[ChatProvider] Upload image error: $e');
      return false;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  void markAsRead() {
    if (_roomId == null) return;

    _socketService.sendReadRoom(_roomId!);

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/chat/messages/$_roomId/read?reader_type=customer');
      http.post(uri).catchError((_) => http.Response('', 500));
    } catch (_) {}
  }

  void notifyTyping(bool isTyping) {
    if (_roomId == null) return;

    if (isTyping) {
      if (!_isSendingTyping) {
        _isSendingTyping = true;
        _socketService.sendTyping(_roomId!, true);

        _typingThrottleTimer?.cancel();
        _typingThrottleTimer = Timer(const Duration(seconds: 2), () {
          _isSendingTyping = false;
        });
      }
    } else {
      _isSendingTyping = false;
      _socketService.sendTyping(_roomId!, false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _typingTimer?.cancel();
    _typingThrottleTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}
