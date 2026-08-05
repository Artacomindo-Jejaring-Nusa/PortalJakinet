class Langganan {
  final int id;
  final int pelangganId;
  final String paket;
  final int harga;
  final String status;
  final String tanggalMulai;

  Langganan({
    required this.id,
    required this.pelangganId,
    required this.paket,
    required this.harga,
    required this.status,
    required this.tanggalMulai,
  });

  factory Langganan.fromJson(Map<String, dynamic> json) {
    return Langganan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      pelangganId: (json['pelanggan_id'] as num?)?.toInt() ?? (json['id_pelanggan'] as num?)?.toInt() ?? 0,
      paket: json['paket'] ?? '',
      harga: (json['harga'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? '',
      tanggalMulai: json['tanggal_mulai'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelanggan_id': pelangganId,
      'paket': paket,
      'harga': harga,
      'status': status,
      'tanggal_mulai': tanggalMulai,
    };
  }
}
