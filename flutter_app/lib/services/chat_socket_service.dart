import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';
import '../models/chat_message.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  bool _isConnected = false;
  bool _isManualDisconnect = false;
  int _reconnectAttempts = 0;

  int? _pelangganId;
  String? _brand;
  String? _name;

  // Event Callbacks
  Function(int roomId)? onRoomConnected;
  Function(ChatMessage message)? onNewMessage;
  Function(String tempId, int messageId, String status)? onAckSent;
  Function(int messageId, String? tempId, String status)? onStatusUpdate;
  Function(int roomId)? onRoomRead;
  Function(bool isTyping)? onTyping;
  Function(bool isConnected)? onConnectionChanged;

  bool get isConnected => _isConnected;

  void connect({
    required int pelangganId,
    required String brand,
    required String name,
  }) {
    _pelangganId = pelangganId;
    _brand = brand;
    _name = name;
    _isManualDisconnect = false;

    _initSocket();
  }

  void _initSocket() {
    if (_pelangganId == null) return;
    _cleanup();

    final queryParams = {
      'role': 'customer',
      'pelanggan_id': _pelangganId.toString(),
      'brand': _brand ?? 'Jakinet',
      'name': _name ?? 'Pelanggan',
    };

    final uri = Uri.parse('${AppConstants.wsBaseUrl}/chat/ws').replace(queryParameters: queryParams);
    debugPrint('[ChatSocket] Connecting to $uri ...');

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionChanged?.call(true);

      _startHeartbeat();

      _subscription = _channel!.stream.listen(
        (message) {
          _handleIncoming(message);
        },
        onDone: () {
          debugPrint('[ChatSocket] Socket closed.');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('[ChatSocket] Socket error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[ChatSocket] Connection exception: $e');
      _handleDisconnect();
    }
  }

  void _handleIncoming(dynamic raw) {
    try {
      final decoded = json.decode(raw.toString());
      if (decoded is! Map<String, dynamic>) return;

      final event = decoded['event']?.toString() ?? '';
      final data = decoded['data'];

      switch (event) {
        case 'room_connected':
          if (data is Map<String, dynamic>) {
            final roomId = int.tryParse(data['room_id']?.toString() ?? '0') ?? 0;
            onRoomConnected?.call(roomId);
          }
          break;

        case 'ack_sent':
          // Ceklis 1 Abu-abu
          if (data is Map<String, dynamic>) {
            final tempId = data['temp_id']?.toString() ?? '';
            final msgId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
            final status = data['status']?.toString() ?? 'sent';
            onAckSent?.call(tempId, msgId, status);
          }
          break;

        case 'new_message':
          if (data is Map<String, dynamic>) {
            final msg = ChatMessage.fromJson(data);
            onNewMessage?.call(msg);

            // Auto-acknowledge delivered to server
            if (msg.id != null && msg.id! > 0) {
              sendAckDelivered(msg.id!, msg.roomId);
            }
          }
          break;

        case 'message_status_update':
          // Ceklis 2 Abu-abu atau Ceklis 2 Biru
          if (data is Map<String, dynamic>) {
            final msgId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;
            final tempId = data['temp_id']?.toString();
            final status = data['status']?.toString() ?? 'delivered';
            onStatusUpdate?.call(msgId, tempId, status);
          }
          break;

        case 'room_read':
          // Seluruh pesan di room telah dibaca oleh lawan bicara -> Ceklis 2 Biru
          if (data is Map<String, dynamic>) {
            final roomId = int.tryParse(data['room_id']?.toString() ?? '0') ?? 0;
            onRoomRead?.call(roomId);
          }
          break;

        case 'typing_indicator':
          if (data is Map<String, dynamic>) {
            final isTyping = data['is_typing'] == true;
            onTyping?.call(isTyping);
          }
          break;
      }
    } catch (e) {
      debugPrint('[ChatSocket] Parse error: $e');
    }
  }

  void sendMessage(String message, String tempId, {String type = 'text', String? attachmentUrl}) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'event': 'send_message',
      'data': {
        'message': message,
        'temp_id': tempId,
        'message_type': type,
        'attachment_url': attachmentUrl,
      },
    };

    _channel!.sink.add(json.encode(payload));
  }

  void sendAckDelivered(int messageId, int roomId) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'event': 'ack_delivered',
      'data': {
        'message_id': messageId,
        'room_id': roomId,
      },
    };

    _channel!.sink.add(json.encode(payload));
  }

  void sendReadRoom(int roomId) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'event': 'read_room',
      'data': {
        'room_id': roomId,
      },
    };

    _channel!.sink.add(json.encode(payload));
  }

  void sendTyping(int roomId, bool isTyping) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'event': 'typing',
      'data': {
        'room_id': roomId,
        'is_typing': isTyping,
      },
    };

    _channel!.sink.add(json.encode(payload));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        // Send small ping payload to keep connection alive through mobile NAT
        try {
          _channel!.sink.add(json.encode({'event': 'ping', 'data': {}}));
        } catch (_) {}
      }
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    onConnectionChanged?.call(false);
    _heartbeatTimer?.cancel();

    if (!_isManualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts > 5) ? 15 : (_reconnectAttempts * 2);
    debugPrint('[ChatSocket] Reconnecting in ${delaySeconds}s (attempt $_reconnectAttempts) ...');

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isManualDisconnect) {
        _initSocket();
      }
    });
  }

  void disconnect() {
    _isManualDisconnect = true;
    _cleanup();
    _isConnected = false;
    onConnectionChanged?.call(false);
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}
