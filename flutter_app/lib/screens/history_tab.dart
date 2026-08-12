import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/customer_provider.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _filter = 'all'; // 'all', 'unpaid', 'paid'

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openUrl(String urlString) async {
    if (urlString.isEmpty || urlString == '#') return;
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Could not launch $urlString: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final invoices = provider.activeInvoices;
    final primaryColor = Theme.of(context).primaryColor;

    final filtered = invoices.where((invoice) {
      if (_filter == 'unpaid') return invoice.statusInvoice != 'Lunas';
      if (_filter == 'paid') return invoice.statusInvoice == 'Lunas';
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Filters
          Row(
            children: [
              _buildFilterChip('all', 'Semua', primaryColor),
              const SizedBox(width: 8),
              _buildFilterChip('unpaid', 'Belum Lunas', primaryColor),
              const SizedBox(width: 8),
              _buildFilterChip('paid', 'Lunas', primaryColor),
            ],
          ),
          const SizedBox(height: 16),

          // Invoice list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada invoice ditemukan',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final invoice = filtered[index];
                      final isPaid = invoice.statusInvoice == 'Lunas';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPaid ? Colors.green : Colors.red,
                                    ),
                                  ),
                                   const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      invoice.invoiceNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.shade50
                                          : (invoice.statusInvoice.toLowerCase() == 'kadaluarsa' || invoice.statusInvoice.toLowerCase() == 'expired')
                                              ? Colors.orange.shade50
                                              : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isPaid 
                                          ? 'Lunas' 
                                          : (invoice.statusInvoice.toLowerCase() == 'kadaluarsa' || invoice.statusInvoice.toLowerCase() == 'expired')
                                              ? 'Terlambat' 
                                              : invoice.statusInvoice,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid
                                            ? Colors.green.shade700
                                            : (invoice.statusInvoice.toLowerCase() == 'kadaluarsa' || invoice.statusInvoice.toLowerCase() == 'expired')
                                                ? Colors.orange.shade700
                                                : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatCurrency(invoice.totalHarga),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Jatuh Tempo: ${_formatDate(invoice.tglJatuhTempo)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.picture_as_pdf),
                                        color: primaryColor,
                                        onPressed: () {
                                          final phone = provider.customerData?.pelanggan.noTelp ?? '';
                                          final email = provider.customerData?.pelanggan.email ?? '';
                                          _openUrl('https://portal.ajnusa.com/api/invoice/${invoice.id}/pdf?phone=$phone&email=$email');
                                        },
                                        tooltip: 'Download PDF',
                                      ),
                                      if (!isPaid && invoice.paymentLink != null) ...[
                                        const SizedBox(width: 4),
                                        ElevatedButton(
                                          onPressed: () => _openUrl(invoice.paymentLink!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('Bayar', style: TextStyle(fontSize: 13, color: Colors.white)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color primaryColor) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: primaryColor,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      showCheckmark: false,
    );
  }
}
