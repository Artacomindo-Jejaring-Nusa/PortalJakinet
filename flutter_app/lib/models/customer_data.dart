import 'pelanggan.dart';
import 'langganan.dart';
import 'invoice.dart';

class CustomerData {
  final Pelanggan pelanggan;
  final Langganan? langganan;
  final List<Invoice> invoices;

  CustomerData({
    required this.pelanggan,
    this.langganan,
    required this.invoices,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    var invoicesList = <Invoice>[];
    if (json['invoices'] != null) {
      invoicesList = (json['invoices'] as List)
          .map((i) => Invoice.fromJson(i))
          .toList();
    }
    return CustomerData(
      pelanggan: Pelanggan.fromJson(json['pelanggan'] ?? {}),
      langganan: json['langganan'] != null
          ? Langganan.fromJson(json['langganan'])
          : null,
      invoices: invoicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pelanggan': pelanggan.toJson(),
      'langganan': langganan?.toJson(),
      'invoices': invoices.map((i) => i.toJson()).toList(),
    };
  }
}
