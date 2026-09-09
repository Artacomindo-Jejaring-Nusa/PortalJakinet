import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/customer_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Pelanggan disalin ke clipboard')),
    );
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
    final customer = provider.customerData?.pelanggan;
    final invoices = provider.activeInvoices;
    final nextInvoice = provider.nextDueInvoice;
    final primaryColor = Theme.of(context).primaryColor;

    if (customer == null) {
      return const Center(child: Text('Data pelanggan tidak ditemukan'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting & ID Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${customer.nama}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _copyToClipboard(context, provider.customerId),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      provider.customerId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status Row (Billing Card & Speed Card)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Billing Status Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 170,
                decoration: BoxDecoration(
                  color: provider.isActive
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: provider.isActive
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFFEE2E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isActive ? 'Tagihan Lunas' : 'Tunggakan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: provider.isActive
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isActive
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        provider.isActive ? 'Aktif' : 'Jatuh Tempo',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (nextInvoice != null) ...[
                      Text(
                        _formatDate(nextInvoice.tglJatuhTempo),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tagihan: ${_formatCurrency(nextInvoice.totalHarga)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Tidak ada tagihan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Speed Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.hargaLayanan?.brand ??
                          (provider.isJelantik ? 'Jelantik' : 'Jakinet'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          provider.speed,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Mbps',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Brand: ${customer.idBrand.isNotEmpty ? customer.idBrand : 'N/A'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Internet Info Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.language, color: primaryColor, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Internet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Broadband UpTo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${provider.speed} Mbps',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: nextInvoice?.paymentLink != null
                    ? () => _openUrl(nextInvoice!.paymentLink!)
                    : null,
                icon: const Icon(Icons.payment, color: Colors.white, size: 16),
                label: const Text(
                  'Pembayaran',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPaymentGuideModal(context, primaryColor, provider.brandWhatsapp),
                icon: Icon(Icons.menu_book_rounded, color: primaryColor, size: 16),
                label: Text(
                  'Cara Bayar',
                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openUrl(provider.brandWhatsapp),
                icon: Icon(Icons.support_agent, color: primaryColor, size: 16),
                label: Text(
                  'CS Support',
                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Recent Payments Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pembayaran Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // To display history tab, we would need control of Shell state,
                // but we can just click BottomNavigationBar or simply notify
              },
              child: Text('Lihat semua', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Belum ada riwayat pembayaran',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...invoices.take(3).map((invoice) {
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                        if (!isPaid && invoice.paymentLink != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _openUrl(invoice.paymentLink!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Bayar',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showPaymentGuideModal(BuildContext context, Color primaryColor, String whatsappUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, color: primaryColor, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Petunjuk Pembayaran Xendit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Text(
                  'Panduan langkah pembayaran tagihan otomatis via Xendit Payment Gateway.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Tabs
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: EdgeInsets.zero,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: primaryColor,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(
                        height: 36,
                        child: Center(
                          child: Text('Bank VA', textAlign: TextAlign.center),
                        ),
                      ),
                      Tab(
                        height: 36,
                        child: Center(
                          child: Text('QRIS & E-Wallet', textAlign: TextAlign.center),
                        ),
                      ),
                      Tab(
                        height: 36,
                        child: Center(
                          child: Text('Gerai Retail', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Contents
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Virtual Account
                      ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: const [
                          _GuideStepItem(
                            num: '1',
                            title: 'Buka Halaman Pembayaran Xendit',
                            desc: 'Klik tombol Pembayaran pada invoice tagihan Anda untuk membuka link resmi Xendit.',
                          ),
                          _GuideStepItem(
                            num: '2',
                            title: 'Pilih Bank Pilihan Anda',
                            desc: 'Pilih Virtual Account bank Anda (BCA, Mandiri, BRI, BNI, Permata, dll) untuk memunculkan nomor Kode VA.',
                          ),
                          _GuideStepItem(
                            num: '3',
                            title: 'Lakukan Transfer VA',
                            desc: 'Buka M-Banking / ATM Anda, pilih Transfer ➔ Virtual Account, tempelkan nomor VA & bayar sesuai nominal.',
                          ),
                          _GuideStepItem(
                            num: '4',
                            title: 'Verifikasi Otomatis',
                            desc: 'Setelah transfer selesai, sistem Xendit akan memverifikasi otomatis dalam hitungan detik tanpa perlu kirim bukti transfer.',
                          ),
                        ],
                      ),
                      // Tab 2: QRIS & E-Wallet
                      ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: const [
                          _GuideStepItem(
                            num: '1',
                            title: 'Pilih QRIS / E-Wallet',
                            desc: 'Pada halaman pembayaran Xendit, pilih opsi QRIS atau E-Wallet (GoPay, ShopeePay, OVO, DANA).',
                          ),
                          _GuideStepItem(
                            num: '2',
                            title: 'Pindai (Scan) Kode QRIS',
                            desc: 'Gunakan fitur Scan QRIS pada aplikasi M-Banking atau E-Wallet pilihan Anda.',
                          ),
                          _GuideStepItem(
                            num: '3',
                            title: 'Selesaikan Transaksi',
                            desc: 'Konfirmasi nama & nominal tagihan, lalu masukkan PIN E-Wallet Anda untuk menyelesaikan pembayaran.',
                          ),
                        ],
                      ),
                      // Tab 3: Gerai Retail
                      ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: const [
                          _GuideStepItem(
                            num: '1',
                            title: 'Pilih Minimarket',
                            desc: 'Pada halaman Xendit, pilih metode pembayaran Alfamart atau Indomaret untuk mendapatkan Kode Pembayaran.',
                          ),
                          _GuideStepItem(
                            num: '2',
                            title: 'Tunjukkan ke Kasir',
                            desc: 'Kunjungi gerai terdekat dan tunjukkan Kode Pembayaran Xendit kepada kasir.',
                          ),
                          _GuideStepItem(
                            num: '3',
                            title: 'Bayar & Simpan Struk',
                            desc: 'Bayar sesuai nominal ke kasir dan simpan struk fisik sebagai bukti transaksi resmi Anda.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Note & Support Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seluruh transaksi Xendit diproses secara terenkripsi & terverifikasi otomatis 24/7.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openUrl(whatsappUrl),
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Bantuan CS WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuideStepItem extends StatelessWidget {
  final String num;
  final String title;
  final String desc;

  const _GuideStepItem({
    required this.num,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
