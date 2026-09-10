class Invoice {
  final int id;
  final int pelangganId;
  final String invoiceNumber;
  final int totalHarga;
  final String statusInvoice;
  final String tglJatuhTempo;
  final String? paidAt;
  final String? tglInvoice;
  final String? metodePembayaran;
  final String? paymentLink;
  final String? brand;
  final String? namaPelanggan;

  Invoice({
    required this.id,
    required this.pelangganId,
    required this.invoiceNumber,
    required this.totalHarga,
    required this.statusInvoice,
    required this.tglJatuhTempo,
    this.paidAt,
    this.tglInvoice,
    this.metodePembayaran,
    this.paymentLink,
    this.brand,
    this.namaPelanggan,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      pelangganId: (json['pelanggan_id'] as num?)?.toInt() ?? (json['id_pelanggan'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      totalHarga: (json['total_harga'] as num?)?.toInt() ?? 0,
      statusInvoice: json['status_invoice'] ?? '',
      tglJatuhTempo: json['tgl_jatuh_tempo'] ?? '',
      paidAt: json['paid_at'],
      tglInvoice: json['tgl_invoice'],
      metodePembayaran: json['metode_pembayaran'],
      paymentLink: json['payment_link'],
      brand: json['brand'],
      namaPelanggan: json['nama_pelanggan'] ?? json['nama'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelanggan_id': pelangganId,
      'invoice_number': invoiceNumber,
      'total_harga': totalHarga,
      'status_invoice': statusInvoice,
      'tgl_jatuh_tempo': tglJatuhTempo,
      'paid_at': paidAt,
      'tgl_invoice': tglInvoice,
      'metode_pembayaran': metodePembayaran,
      'payment_link': paymentLink,
      'brand': brand,
      'nama_pelanggan': namaPelanggan,
    };
  }

  bool isExpired() {
    final status = statusInvoice.toLowerCase();
    
    // Explicitly hide any invoice marked as Expired, Kadaluarsa, or Batal
    if (status.contains('expired') ||
        status.contains('kadaluarsa') ||
        status.contains('kadaluwarsa') ||
        status.contains('batal') ||
        status.contains('cancel')) {
      return true;
    }

    return false;
  }
}



