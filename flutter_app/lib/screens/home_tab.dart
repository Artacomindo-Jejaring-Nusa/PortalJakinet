import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/customer_provider.dart';
import '../widgets/app_tutorial_overlay.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  // GlobalKeys for Tutorial Bar
  final GlobalKey _keyProfileCard = GlobalKey();
  final GlobalKey _keyBillingCard = GlobalKey();
  final GlobalKey _keySpeedCard = GlobalKey();
  final GlobalKey _keyQuickActions = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeTutorial();
    });
  }

  Future<void> _checkFirstTimeTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('has_seen_home_tutorial_v1') ?? false;
      if (!hasSeen && mounted) {
        // Beri sedikit delay agar widget selesai render sempurna
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          showTutorial();
        }
      }
    } catch (e) {
      print('Error checking tutorial: $e');
    }
  }

  void showTutorial() {
    AppTutorialOverlay.show(
      context: context,
      steps: [
        TutorialStep(
          targetKey: _keyProfileCard,
          title: 'Profil & ID Pelanggan',
          description:
              'Kartu ini menampilkan nama dan ID pelanggan Anda. Ketuk untuk menyalin ID secara instan saat konfirmasi pembayaran atau lapor gangguan.',
          icon: Icons.person_rounded,
          borderRadius: 20,
        ),
        TutorialStep(
          targetKey: _keyBillingCard,
          title: 'Status & Jatuh Tempo Tagihan',
          description:
              'Pantau status pembayaran langganan Anda secara real-time. Anda bisa melihat status aktif, tanggal jatuh tempo, dan nominal tagihan berjalan.',
          icon: Icons.receipt_long_rounded,
          borderRadius: 18,
        ),
        TutorialStep(
          targetKey: _keySpeedCard,
          title: 'Kecepatan Internet Fiber',
          description:
              'Menampilkan paket kecepatan internet aktif Anda tanpa batasan kuota (unlimited). Layanan siap digunakan 24/7.',
          icon: Icons.speed_rounded,
          borderRadius: 18,
        ),
        TutorialStep(
          targetKey: _keyQuickActions,
          title: 'Menu Layanan & Pembayaran',
          description:
              'Akses cepat untuk bayar tagihan via Xendit (VA / QRIS), membaca panduan cara bayar, atau menghubungi Customer Care WhatsApp.',
          icon: Icons.flash_on_rounded,
          borderRadius: 16,
        ),
      ],
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_home_tutorial_v1', true);
      },
    );
  }

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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ID Pelanggan $text berhasil disalin',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ==========================================
        // 1. GREETING & ID CARD (PEMANIS + MODERN UI)
        // ==========================================
        Container(
          key: _keyProfileCard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                Color.lerp(primaryColor, const Color(0xFF0F172A), 0.35) ??
                    const Color(0xFF1E3A8A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Ornamen dekorasi latar belakang (Pemanis)
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -35,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Isi Konten Kartu
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Atas: Greeting & Status Koneksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.nama,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Status Pill (Pemanis)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4ADE80), // Vibrant Green
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Baris Bawah: Customer ID Pill (dengan Salin Button)
                    InkWell(
                      onTap: () => _copyToClipboard(context, provider.customerId),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.customerId,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Salin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ========================================================
        // 2. STATUS ROW (BILLING STATUS & SPEED CARD) - PEMANIS
        // ========================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU STATUS TAGIHAN
            Expanded(
              child: Container(
                key: _keyBillingCard,
                padding: const EdgeInsets.all(16),
                height: 175,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: provider.isActive
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFFECACA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Baris: Judul & Icon Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.isActive ? 'Tagihan' : 'Tunggakan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.isActive
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFFEF2F2),
                          ),
                          child: Icon(
                            provider.isActive
                                ? Icons.verified_user_rounded
                                : Icons.warning_amber_rounded,
                            size: 15,
                            color: provider.isActive
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.isActive ? 'Lunas' : 'Jatuh Tempo',
                        style: TextStyle(
                          fontSize: 10,
                          color: provider.isActive
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Detail Tagihan
                    if (nextInvoice != null) ...[
                      Text(
                        _formatCurrency(nextInvoice.totalHarga),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDate(nextInvoice.tglJatuhTempo),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'Tidak ada tagihan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Layanan aktif lancar',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // KARTU KECEPATAN (BRAND AJN-03 DIHILANGKAN, DIBUAT MODERN)
            Expanded(
              child: Container(
                key: _keySpeedCard,
                padding: const EdgeInsets.all(16),
                height: 175,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Nama Layanan & Speed Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            customer.hargaLayanan?.brand ??
                                (provider.isJelantik ? 'Jelantik' : 'Jakinet'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            Icons.speed_rounded,
                            size: 15,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Kecepatan Mbps
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          provider.speed,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mbps',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Pengganti Brand: ajn-03 (Pemanis: Fiber Unlimited Badge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFDCFCE7),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 12,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Fiber Unlimited',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ==========================================
        // 3. INTERNET INFO BAR (MODERN STATUS)
        // ==========================================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Status Jaringan: ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Text(
                'Normal & Terhubung',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.wifi_tethering_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ========================================================
        // 4. TOMBOL AKSI CEPAT (PEMBAYARAN, CARA BAYAR, CS SUPPORT)
        // ========================================================
        Container(
          key: _keyQuickActions,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: nextInvoice?.paymentLink != null
                      ? () => _openUrl(nextInvoice!.paymentLink!)
                      : null,
                  icon: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Pembayaran',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentGuideModal(
                    context,
                    primaryColor,
                    provider.brandWhatsapp,
                  ),
                  icon: Icon(
                    Icons.menu_book_rounded,
                    color: primaryColor,
                    size: 16,
                  ),
                  label: Text(
                    'Cara Bayar',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUrl(provider.brandWhatsapp),
                  icon: Icon(
                    Icons.support_agent_rounded,
                    color: primaryColor,
                    size: 16,
                  ),
                  label: Text(
                    'CS WhatsApp',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ==========================================
        // 5. RECENT PAYMENTS / RIWAYAT PEMBAYARAN
        // ==========================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pembayaran Terakhir',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: showTutorial,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tutorial',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada riwayat pembayaran',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...invoices.take(3).map((invoice) {
            final isPaid = invoice.statusInvoice == 'Lunas';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPaid
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
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
                              ? const Color(0xFFDCFCE7)
                              : (invoice.statusInvoice.toLowerCase() ==
                                          'kadaluarsa' ||
                                      invoice.statusInvoice.toLowerCase() ==
                                          'expired')
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid
                              ? 'Lunas'
                              : (invoice.statusInvoice.toLowerCase() ==
                                          'kadaluarsa' ||
                                      invoice.statusInvoice.toLowerCase() ==
                                          'expired')
                                  ? 'Terlambat'
                                  : invoice.statusInvoice,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? const Color(0xFF15803D)
                                : (invoice.statusInvoice.toLowerCase() ==
                                            'kadaluarsa' ||
                                        invoice.statusInvoice.toLowerCase() ==
                                            'expired')
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jatuh Tempo: ${_formatDate(invoice.tglJatuhTempo)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
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
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Bayar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // MODAL PETUNJUK CARA BAYAR XENDIT
  // ==========================================
  void _showPaymentGuideModal(
    BuildContext context,
    Color primaryColor,
    String whatsappUrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.82,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Petunjuk Pembayaran Xendit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                      tabs: const [
                        Tab(text: 'Virtual Account'),
                        Tab(text: 'QRIS & E-Wallet'),
                        Tab(text: 'Gerai Retail'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tab Content
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
                              desc:
                                  'Klik tombol Pembayaran pada invoice tagihan Anda untuk membuka link resmi Xendit.',
                            ),
                            _GuideStepItem(
                              num: '2',
                              title: 'Pilih Bank Pilihan Anda',
                              desc:
                                  'Pilih Virtual Account bank Anda (BCA, Mandiri, BRI, BNI, Permata, dll) untuk memunculkan nomor Kode VA.',
                            ),
                            _GuideStepItem(
                              num: '3',
                              title: 'Lakukan Transfer VA',
                              desc:
                                  'Buka M-Banking / ATM Anda, pilih Transfer > Virtual Account, tempelkan nomor VA & bayar sesuai nominal.',
                            ),
                            _GuideStepItem(
                              num: '4',
                              title: 'Verifikasi Otomatis',
                              desc:
                                  'Setelah transfer selesai, sistem Xendit akan memverifikasi otomatis dalam hitungan detik tanpa perlu kirim bukti transfer.',
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
                              desc:
                                  'Pada halaman pembayaran Xendit, pilih opsi QRIS atau E-Wallet (GoPay, ShopeePay, OVO, DANA).',
                            ),
                            _GuideStepItem(
                              num: '2',
                              title: 'Pindai (Scan) Kode QRIS',
                              desc:
                                  'Gunakan fitur Scan QRIS pada aplikasi M-Banking atau E-Wallet pilihan Anda.',
                            ),
                            _GuideStepItem(
                              num: '3',
                              title: 'Selesaikan Transaksi',
                              desc:
                                  'Konfirmasi nama & nominal tagihan, lalu masukkan PIN E-Wallet Anda untuk menyelesaikan pembayaran.',
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
                              desc:
                                  'Pada halaman Xendit, pilih metode pembayaran Alfamart untuk mendapatkan Kode Pembayaran.',
                            ),
                            _GuideStepItem(
                              num: '2',
                              title: 'Tunjukkan ke Kasir',
                              desc:
                                  'Kunjungi gerai terdekat dan tunjukkan Kode Pembayaran Xendit kepada kasir.',
                            ),
                            _GuideStepItem(
                              num: '3',
                              title: 'Bayar & Simpan Struk',
                              desc:
                                  'Bayar sesuai nominal ke kasir dan simpan struk fisik sebagai bukti transaksi resmi Anda.',
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
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF1D4ED8),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seluruh transaksi Xendit diproses secara terenkripsi & terverifikasi otomatis 24/7.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E40AF),
                            ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
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
