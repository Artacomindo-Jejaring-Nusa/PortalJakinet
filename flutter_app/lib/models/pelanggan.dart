class Pelanggan {
  final int id;
  final String noKtp;
  final String nama;
  final String alamat;
  final String alamat2;
  final String tglInstalasi;
  final String blok;
  final String unit;
  final String noTelp;
  final String email;
  final String idBrand;
  final String layanan;
  final HargaLayanan? hargaLayanan;
  final String createdAt;
  final String updatedAt;

  Pelanggan({
    required this.id,
    required this.noKtp,
    required this.nama,
    required this.alamat,
    required this.alamat2,
    required this.tglInstalasi,
    required this.blok,
    required this.unit,
    required this.noTelp,
    required this.email,
    required this.idBrand,
    required this.layanan,
    this.hargaLayanan,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pelanggan.fromJson(Map<String, dynamic> json) {
    return Pelanggan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      noKtp: json['no_ktp'] ?? '',
      nama: json['nama'] ?? '',
      alamat: json['alamat'] ?? '',
      alamat2: json['alamat_2'] ?? '',
      tglInstalasi: json['tgl_instalasi'] ?? '',
      blok: json['blok'] ?? '',
      unit: json['unit'] ?? '',
      noTelp: json['no_telp'] ?? '',
      email: json['email'] ?? '',
      idBrand: json['id_brand'] ?? '',
      layanan: json['layanan'] ?? '',
      hargaLayanan: json['harga_layanan'] != null
          ? HargaLayanan.fromJson(json['harga_layanan'])
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_ktp': noKtp,
      'nama': nama,
      'alamat': alamat,
      'alamat_2': alamat2,
      'tgl_instalasi': tglInstalasi,
      'blok': blok,
      'unit': unit,
      'no_telp': noTelp,
      'email': email,
      'id_brand': idBrand,
      'layanan': layanan,
      'harga_layanan': hargaLayanan?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class HargaLayanan {
  final String idBrand;
  final String brand;
  final double pajak;
  final String xenditKeyName;

  HargaLayanan({
    required this.idBrand,
    required this.brand,
    required this.pajak,
    required this.xenditKeyName,
  });

  factory HargaLayanan.fromJson(Map<String, dynamic> json) {
    return HargaLayanan(
      idBrand: json['id_brand'] ?? '',
      brand: json['brand'] ?? '',
      pajak: (json['pajak'] as num?)?.toDouble() ?? 0.0,
      xenditKeyName: json['xendit_key_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_brand': idBrand,
      'brand': brand,
      'pajak': pajak,
      'xendit_key_name': xenditKeyName,
    };
  }
}
