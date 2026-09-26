class TechnicianTicketAction {
  final String actionType;
  final String note;
  final String userName;
  final String createdAt;

  TechnicianTicketAction({
    required this.actionType,
    required this.note,
    required this.userName,
    required this.createdAt,
  });

  factory TechnicianTicketAction.fromJson(Map<String, dynamic> json) {
    String user = 'Petugas';
    if (json['user'] is String) {
      user = json['user'];
    } else if (json['user'] is Map) {
      user = json['user']['nama'] ?? json['user']['name'] ?? 'Petugas';
    } else if (json['user_name'] != null) {
      user = json['user_name'];
    }

    return TechnicianTicketAction(
      actionType: json['action_type'] ?? json['type'] ?? json['action'] ?? 'Catatan',
      note: json['notes'] ?? json['note'] ?? json['description'] ?? json['pesan'] ?? '',
      userName: user,
      createdAt: json['created_at'] ?? json['date'] ?? json['tgl'] ?? '',
    );
  }
}

class TechnicianTicket {
  final int id;
  final String ticketNumber;
  final int pelangganId;
  final String customerName;
  final String customerPhone;
  final String address;
  final String title;
  final String category;
  final String description;
  final String priority; // High, Medium, Low
  final String status; // Open, On Progress, Resolved, Closed
  final String solution;
  final String createdAt;
  final List<TechnicianTicketAction> actions;

  TechnicianTicket({
    required this.id,
    required this.ticketNumber,
    required this.pelangganId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.solution,
    required this.createdAt,
    this.actions = const [],
  });

  factory TechnicianTicket.fromJson(Map<String, dynamic> json) {
    final pelanggan = json['pelanggan'] ?? {};
    
    List<TechnicianTicketAction> actionList = [];
    final rawActions = json['actions'] ?? json['action_history'] ?? json['history'] ?? json['logs'];
    if (rawActions != null && rawActions is List) {
      actionList = rawActions
          .map((item) => TechnicianTicketAction.fromJson(item))
          .toList();
    }

    final ticketNo = json['ticket_number'] ??
        json['no_tiket'] ??
        json['ticket_no'] ??
        json['number'] ??
        'TKT-${json['id']}';

    final priorityStr = json['prioritas'] ?? json['priority'] ?? 'Medium';
    final statusStr = json['status'] ?? 'Open';

    return TechnicianTicket(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      ticketNumber: ticketNo.toString(),
      pelangganId: json['pelanggan_id'] ?? json['id_pelanggan'] ?? 0,
      customerName: pelanggan['nama'] ?? json['nama_pelanggan'] ?? json['customer_name'] ?? 'Pelanggan',
      customerPhone: pelanggan['no_telp'] ?? pelanggan['whatsapp'] ?? json['no_telp'] ?? '',
      address: pelanggan['alamat'] ?? json['alamat'] ?? 'Lokasi Pelanggan',
      title: json['judul'] ?? json['title'] ?? json['subject'] ?? 'Laporan Gangguan',
      category: json['kategori'] ?? json['category'] ?? 'Jaringan',
      description: json['deskripsi'] ?? json['description'] ?? json['pesan'] ?? '',
      priority: priorityStr.toString(),
      status: statusStr.toString(),
      solution: json['solusi'] ?? json['solution'] ?? '',
      createdAt: json['tgl_laporan'] ?? json['created_at'] ?? '',
      actions: actionList,
    );
  }

  TechnicianTicket copyWith({
    String? status,
    String? solution,
    List<TechnicianTicketAction>? actions,
  }) {
    return TechnicianTicket(
      id: id,
      ticketNumber: ticketNumber,
      pelangganId: pelangganId,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      title: title,
      category: category,
      description: description,
      priority: priority,
      status: status ?? this.status,
      solution: solution ?? this.solution,
      createdAt: createdAt,
      actions: actions ?? this.actions,
    );
  }
}
