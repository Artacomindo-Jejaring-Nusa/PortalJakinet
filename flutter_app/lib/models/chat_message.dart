class ChatMessage {
  final int? id;
  final int roomId;
  final String senderType; // 'customer', 'admin', 'system'
  final String senderName;
  final String message;
  final String messageType; // 'text', 'image', 'file'
  final String? attachmentUrl;
  String status; // 'pending', 'sent', 'delivered', 'read'
  final DateTime createdAt;
  final String? tempId;

  ChatMessage({
    this.id,
    required this.roomId,
    required this.senderType,
    required this.senderName,
    required this.message,
    this.messageType = 'text',
    this.attachmentUrl,
    this.status = 'pending',
    required this.createdAt,
    this.tempId,
  });

  bool get isMe => senderType == 'customer';
  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isRead => status == 'read';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ChatMessage(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      roomId: json['room_id'] is int ? json['room_id'] : int.tryParse(json['room_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'customer',
      senderName: json['sender_name']?.toString() ?? 'Customer',
      message: json['message']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      attachmentUrl: json['attachment_url']?.toString(),
      status: json['status']?.toString() ?? 'sent',
      createdAt: parsedDate,
      tempId: json['temp_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_type': senderType,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'temp_id': tempId,
    };
  }
}
