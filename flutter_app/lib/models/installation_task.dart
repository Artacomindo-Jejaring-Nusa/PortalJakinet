class InstallationTask {
  final int id;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String packageName;
  final String brand;
  final String registrationDate;
  final String installationTargetDate;
  final String status; // Pending, In Progress, Installed, Cancelled
  final String notes;

  InstallationTask({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.packageName,
    required this.brand,
    required this.registrationDate,
    required this.installationTargetDate,
    required this.status,
    this.notes = '',
  });

  factory InstallationTask.fromJson(Map<String, dynamic> json) {
    final pelanggan = json['pelanggan'] ?? json;
    final hargaLayanan = pelanggan['harga_layanan'] ?? json['harga_layanan'];
    
    return InstallationTask(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      customerName: pelanggan['nama'] ?? json['nama_pelanggan'] ?? json['customer_name'] ?? 'Pelanggan Baru',
      phone: pelanggan['no_telp'] ?? pelanggan['whatsapp'] ?? json['phone'] ?? '',
      email: pelanggan['email'] ?? '',
      address: _formatAddress(pelanggan),
      packageName: pelanggan['layanan'] ?? json['paket'] ?? 'Broadband Internet',
      brand: hargaLayanan != null ? (hargaLayanan['brand'] ?? '') : (json['brand'] ?? 'Jelantik'),
      registrationDate: json['created_at'] ?? json['tgl_instalasi'] ?? '',
      installationTargetDate: json['tgl_instalasi'] ?? json['target_date'] ?? 'Menunggu Jadwal',
      status: json['status_instalasi'] ?? json['status'] ?? 'Pending',
      notes: json['catatan'] ?? json['notes'] ?? '',
    );
  }

  static String _formatAddress(Map<String, dynamic> json) {
    final alamat = json['alamat'] ?? '';
    final blok = json['blok'] ?? '';
    final unit = json['unit'] ?? '';

    List<String> parts = [];
    if (alamat.toString().isNotEmpty) parts.add(alamat.toString());
    if (blok.toString().isNotEmpty) parts.add('Blok ${blok.toString()}');
    if (unit.toString().isNotEmpty) parts.add('No. ${unit.toString()}');

    return parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak terisi';
  }

  InstallationTask copyWith({
    String? status,
    String? notes,
  }) {
    return InstallationTask(
      id: id,
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      packageName: packageName,
      brand: brand,
      registrationDate: registrationDate,
      installationTargetDate: installationTargetDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
