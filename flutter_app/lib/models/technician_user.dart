class TechnicianUser {
  final int id;
  final String name;
  final String email;
  final String whatsapp;
  final String role;
  final String status;
  final List<String> permissions;

  TechnicianUser({
    required this.id,
    required this.name,
    required this.email,
    required this.whatsapp,
    required this.role,
    required this.status,
    this.permissions = const [],
  });

  factory TechnicianUser.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    String roleName = 'Teknisi';

    if (json['role'] != null) {
      if (json['role'] is String) {
        roleName = json['role'];
      } else if (json['role'] is Map) {
        roleName = json['role']['name'] ?? json['role']['nama'] ?? 'Teknisi';
        if (json['role']['permissions'] != null && json['role']['permissions'] is List) {
          perms = (json['role']['permissions'] as List)
              .map((p) => p is Map ? (p['name'] ?? '').toString() : p.toString())
              .toList();
        }
      }
    }

    if (perms.isEmpty && json['permissions'] != null && json['permissions'] is List) {
      perms = (json['permissions'] as List)
          .map((p) => p is Map ? (p['name'] ?? '').toString() : p.toString())
          .toList();
    }

    return TechnicianUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['nama'] ?? json['name'] ?? json['user_name'] ?? 'Teknisi',
      email: json['email'] ?? '',
      whatsapp: json['phone_no'] ?? json['whatsapp'] ?? json['no_telp'] ?? json['phone'] ?? '',
      role: roleName,
      status: json['is_active'] == true ? 'Active' : (json['status'] ?? 'Active'),
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'whatsapp': whatsapp,
      'role': role,
      'status': status,
      'permissions': permissions,
    };
  }
}
