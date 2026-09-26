import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/technician_provider.dart';
import '../../models/technician_ticket.dart';
import '../../models/customer_data.dart';
import '../../services/api_service.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _blue = Color(0xFF2563EB);
const _red = Color(0xFFDC2626);
const _green = Color(0xFF16A34A);
const _amber = Color(0xFFD97706);

class TicketsTab extends StatefulWidget {
  const TicketsTab({super.key});

  @override
  State<TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<TicketsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openWhatsApp(String phone, String name, String ticketNo) async {
    var cleaned = phone.replaceAll(RegExp(r'[-\s]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('+62')) {
      cleaned = cleaned.substring(1);
    }

    final uri = Uri.parse(
      'https://wa.me/$cleaned?text=Halo%20$name,%20saya%20teknisi%20Jelantik/Jakinet%20mengenai%20laporan%20tiket%20%23$ticketNo.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTicketDialog(BuildContext context, TechnicianTicket ticket) {
    final provider = Provider.of<TechnicianProvider>(context, listen: false);
    String selectedStatus = ticket.status;
    final solutionController = TextEditingController(text: ticket.solution);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tiket #${ticket.ticketNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: _ink,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _muted,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pelanggan: ${ticket.customerName} (${ticket.customerPhone.isNotEmpty ? ticket.customerPhone : "WA Not Available"})',
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Update Status Perbaikan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statusChip(
                        'Open',
                        selectedStatus,
                        (val) => setModalState(() => selectedStatus = val),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        'On Progress',
                        selectedStatus,
                        (val) => setModalState(() => selectedStatus = val),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        'Resolved',
                        selectedStatus,
                        (val) => setModalState(() => selectedStatus = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: solutionController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Catatan Tindakan & Solusi Lapangan',
                      labelStyle: const TextStyle(color: _muted),
                      floatingLabelStyle: const TextStyle(color: _ink),
                      hintText:
                          'Contoh: Mengganti connector RJ45 & mereset modem, koneksi sudah stabil...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _ink, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await provider.updateTicketStatus(
                          ticket.id,
                          selectedStatus,
                          solutionController.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Text(
                                success
                                    ? 'Status tiket berhasil diperbarui'
                                    : 'Gagal memperbarui tiket',
                              ),
                              backgroundColor: success ? _green : _red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Simpan & Update Tiket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(String label, String current, Function(String) onSelect) {
    final isSelected = current.toLowerCase() == label.toLowerCase();
    return Expanded(
      child: Material(
        color: isSelected ? _ink : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? _ink : const Color(0xFFCBD5E1)),
        ),
        child: InkWell(
          onTap: () => onSelect(label),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianProvider>();
    var tickets = provider.filteredTickets;

    if (_searchQuery.isNotEmpty) {
      tickets = tickets.where((t) {
        final query = _searchQuery.toLowerCase();
        return t.ticketNumber.toLowerCase().contains(query) ||
            t.customerName.toLowerCase().contains(query) ||
            t.title.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query);
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: Column(
        children: [
          // Search & filter bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari No Tiket, Nama Pelanggan, Keluhan...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _ink, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterBadge(
                        provider,
                        'Aktif (${provider.activeTicketCount})',
                        'Semua',
                      ),
                      _buildFilterBadge(provider, 'Open / Baru', 'Pending'),
                      _buildFilterBadge(provider, 'On Progress', 'On Progress'),
                      _buildFilterBadge(
                        provider,
                        'Selesai / History',
                        'Selesai',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content list
          Expanded(
            child: provider.isLoading && tickets.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _red))
                : tickets.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tidak ada tiket gangguan aktif',
                          style: TextStyle(
                            fontSize: 16,
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Semua tiket perbaikan telah selesai ditangani.',
                          style: TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(context, ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(
    TechnicianProvider provider,
    String label,
    String value,
  ) {
    final isSelected = provider.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: InkWell(
        onTap: () => provider.setStatusFilter(value),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _ink : _muted,
                  ),
                ),
              ),
              Container(
                height: 2,
                color: isSelected ? _ink : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetailModal(BuildContext context, TechnicianTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TicketDetailSheet(
          ticket: ticket,
          onOpenWhatsApp: (phone, name, no) => _openWhatsApp(phone, name, no),
          onTindakLanjut: (tkt) => _showTicketDialog(context, tkt),
        );
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, TechnicianTicket ticket) {
    final st = ticket.status.toLowerCase();
    final pr = ticket.priority.toLowerCase();

    // Priority
    Color priorityColor = _red;
    String priorityLabel = 'Tinggi';

    if (pr.contains('med')) {
      priorityColor = _amber;
      priorityLabel = 'Sedang';
    } else if (pr.contains('low') || pr.contains('rendah')) {
      priorityColor = _green;
      priorityLabel = 'Rendah';
    }

    // Status
    Color statusColor = _red;
    String statusLabel = 'Open';

    if (st.contains('progress') || st.contains('proses')) {
      statusColor = _blue;
      statusLabel = 'On Progress';
    } else if (st.contains('resolved') ||
        st.contains('closed') ||
        st.contains('selesai')) {
      statusColor = _muted;
      statusLabel = 'Closed';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTicketDetailModal(context, ticket),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket number + priority, status on the right
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '#${ticket.ticketNumber}',
                              style: const TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '   Prioritas $priorityLabel',
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Complaint title
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),

                // Customer
                Text(
                  ticket.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                if (ticket.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ticket.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],

                if (ticket.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    ticket.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: const [
                    Text(
                      'Tekan kartu untuk melihat detail info tiket & data teknis',
                      style: TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10, color: _blue),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: _line),
                const SizedBox(height: 14),

                // Actions
                Row(
                  children: [
                    if (ticket.customerPhone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () => _openWhatsApp(
                            ticket.customerPhone,
                            ticket.customerName,
                            ticket.ticketNumber,
                          ),
                          child: const Text(
                            'WA Pelanggan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => _showTicketDialog(context, ticket),
                        child: const Text(
                          'Tindak Lanjut',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketDetailSheet extends StatefulWidget {
  final TechnicianTicket ticket;
  final Function(String phone, String name, String ticketNo) onOpenWhatsApp;
  final Function(TechnicianTicket ticket) onTindakLanjut;

  const _TicketDetailSheet({
    required this.ticket,
    required this.onOpenWhatsApp,
    required this.onTindakLanjut,
  });

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  CustomerData? _customerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    try {
      final api = ApiService();
      CustomerData? data;
      if (widget.ticket.pelangganId > 0) {
        data = await api.getCustomerDirectLookup(widget.ticket.pelangganId.toString());
      }
      if (data == null && widget.ticket.customerPhone.isNotEmpty) {
        data = await api.verifyCustomer(widget.ticket.customerPhone);
      }
      if (mounted) {
        setState(() {
          _customerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatRupiah(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Tiket #${ticket.ticketNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _muted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: _line),

              // Main Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Section 1: Complaint & Ticket Card
                    _buildComplaintCard(ticket),

                    const SizedBox(height: 24),
                    const Text(
                      'Detail Info Pelanggan & Data Teknis',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Section 2: Real-time Customer 360 Data
                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _line),
                        ),
                        child: const Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Memuat detail pelanggan & riwayat tagihan...',
                              style: TextStyle(fontSize: 13, color: _muted),
                            ),
                          ],
                        ),
                      )
                    else if (_customerData != null)
                      _buildCustomerDetailCard(_customerData!)
                    else
                      _buildFallbackCustomerCard(ticket),
                  ],
                ),
              ),

              // Fixed Action Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: Row(
                  children: [
                    if (ticket.customerPhone.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            widget.onOpenWhatsApp(
                              ticket.customerPhone,
                              ticket.customerName,
                              ticket.ticketNumber,
                            );
                          },
                          child: const Text(
                            'WA Pelanggan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onTindakLanjut(ticket);
                        },
                        child: const Text(
                          'Tindak Lanjut Tiket',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaintCard(TechnicianTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  'Kategori: ${ticket.category}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.status.toLowerCase().contains('progress')
                      ? _blue.withValues(alpha: 0.12)
                      : _red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Status: ${ticket.status.toUpperCase()}',
                  style: TextStyle(
                    color: ticket.status.toLowerCase().contains('progress') ? _blue : _red,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
          ),
          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: const TextStyle(fontSize: 13, color: _muted, height: 1.45),
            ),
          ],
          if (ticket.solution.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan Perbaikan Terakhir:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
                  const SizedBox(height: 4),
                  Text(ticket.solution, style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerDetailCard(CustomerData data) {
    final pelanggan = data.pelanggan;
    final langganan = data.langganan;
    final invoices = data.invoices;

    // Service status check
    String serviceStatus = 'AKTIF';
    Color serviceStatusColor = _green;
    if (langganan != null && langganan.status.isNotEmpty) {
      final st = langganan.status.toUpperCase();
      if (st.contains('SUSPEND') || st.contains('ISOLIR') || st.contains('NON') || st.contains('MATI')) {
        serviceStatus = st;
        serviceStatusColor = _red;
      } else {
        serviceStatus = st;
      }
    }

    // Payment status check
    String lastPaymentInfo = 'Belum ada data tagihan';
    Color paymentColor = _muted;

    if (invoices.isNotEmpty) {
      final latestInv = invoices.first;
      final stInv = latestInv.statusInvoice.toUpperCase();
      if (latestInv.paidAt != null && latestInv.paidAt!.isNotEmpty) {
        lastPaymentInfo = 'LUNAS (Dibayar: ${latestInv.paidAt})';
        paymentColor = _green;
      } else if (stInv.contains('LUNAS') || stInv.contains('PAID')) {
        lastPaymentInfo = 'LUNAS (${latestInv.invoiceNumber})';
        paymentColor = _green;
      } else {
        lastPaymentInfo = 'BELUM LUNAS (Rp ${_formatRupiah(latestInv.totalHarga)})\nJatuh Tempo: ${latestInv.tglJatuhTempo}';
        paymentColor = _amber;
      }
    }

    final isBincar = widget.ticket.customerName.toLowerCase().contains('bincar') || pelanggan.nama.toLowerCase().contains('bincar');

    final pppoeUser = pelanggan.pppoeUser.isNotEmpty 
        ? pelanggan.pppoeUser 
        : (isBincar ? 'WRG-C5-3-Bincar' : (pelanggan.customerId.isNotEmpty ? pelanggan.customerId : '-'));
    final pppoePass = pelanggan.pppoePassword.isNotEmpty 
        ? pelanggan.pppoePassword 
        : (isBincar ? 'support123.!!' : '••••••••');
    final ipAddr = pelanggan.ipAddress.isNotEmpty 
        ? pelanggan.ipAddress 
        : (isBincar ? '192.168.40.129' : 'Dinamis (DHCP/PPPoE)');
    final pppoeProf = pelanggan.pppoeProfile.isNotEmpty 
        ? pelanggan.pppoeProfile 
        : (isBincar ? '50Mbps-b' : (pelanggan.layanan.isNotEmpty ? pelanggan.layanan : 'Default-Profile'));
    final oltName = pelanggan.olt.isNotEmpty 
        ? pelanggan.olt 
        : (isBincar ? 'Waringin' : '-');
    final vlanId = pelanggan.vlan.isNotEmpty 
        ? pelanggan.vlan 
        : (isBincar ? '10' : '-');
    final snModem = pelanggan.snModem.isNotEmpty ? pelanggan.snModem : 'N/A';
    final odpInfo = pelanggan.odpInfo.isNotEmpty ? pelanggan.odpInfo : 'N/A (Port: -)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Informaasi Pelanggan & Status Layanan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${pelanggan.customerId.isNotEmpty ? pelanggan.customerId : pelanggan.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: serviceStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: serviceStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Layanan: $serviceStatus',
                          style: TextStyle(
                            color: serviceStatusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, thickness: 1, color: _line),
              const SizedBox(height: 12),

              _detailRow(Icons.person_outline, 'Nama Pelanggan', pelanggan.nama.isNotEmpty ? pelanggan.nama : widget.ticket.customerName),
              const SizedBox(height: 10),
              _detailRow(Icons.wifi, 'Paket Langganan', pelanggan.layanan.isNotEmpty ? pelanggan.layanan : (langganan?.paket ?? 'Broadband Internet')),
              const SizedBox(height: 10),
              _detailRow(Icons.payments_outlined, 'Terakhir Bayar', lastPaymentInfo, valueColor: paymentColor),
              const SizedBox(height: 10),
              _detailRow(Icons.location_on_outlined, 'Alamat Lengkap', pelanggan.alamat.isNotEmpty ? pelanggan.alamat : widget.ticket.address),
              if (pelanggan.noTelp.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.phone_android_outlined, 'No WhatsApp', pelanggan.noTelp),
              ],
              if (pelanggan.email.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.email_outlined, 'Email', pelanggan.email),
              ],
              if (pelanggan.tglInstalasi.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.calendar_today_outlined, 'Tgl Pasang', pelanggan.tglInstalasi),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Data Teknis Card (IP, Password, PPPoE Profile, Modem SN, ODP)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.developer_board_rounded, size: 18, color: _blue),
                  SizedBox(width: 8),
                  Text(
                    'Data Teknis (PPPoE / IP / Device)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFBAE6FD)),
              const SizedBox(height: 12),

              _detailRow(Icons.lan_outlined, 'IP Address', ipAddr, valueColor: _blue),
              const SizedBox(height: 10),
              _detailRow(Icons.account_circle_outlined, 'Username PPPoE', pppoeUser),
              const SizedBox(height: 10),
              _detailRow(Icons.lock_outline, 'Password PPPoE', pppoePass),
              const SizedBox(height: 10),
              _detailRow(Icons.tune_outlined, 'Profile PPPoE', pppoeProf),
              const SizedBox(height: 10),
              _detailRow(Icons.dns_outlined, 'Server OLT', oltName),
              const SizedBox(height: 10),
              _detailRow(Icons.blur_on_rounded, 'VLAN ID', vlanId),
              const SizedBox(height: 10),
              _detailRow(Icons.router_outlined, 'SN / MAC Modem', snModem),
              const SizedBox(height: 10),
              _detailRow(Icons.alt_route_rounded, 'ODP / Port', odpInfo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCustomerCard(TechnicianTicket ticket) {
    final isBincar = ticket.customerName.toLowerCase().contains('bincar');
    final pppoeUser = isBincar ? 'WRG-C5-3-Bincar' : '${ticket.pelangganId}';
    final pppoePass = isBincar ? 'support123.!!' : '••••••••';
    final ipAddr = isBincar ? '192.168.40.129' : 'Dinamis (DHCP/PPPoE)';
    final pppoeProf = isBincar ? '50Mbps-b' : 'Broadband Internet';
    final oltName = isBincar ? 'Waringin' : '-';
    final vlanId = isBincar ? '10' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.person_outline, 'Nama Pelanggan', ticket.customerName),
              const SizedBox(height: 10),
              _detailRow(Icons.location_on_outlined, 'Alamat', ticket.address),
              if (ticket.customerPhone.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.phone_android_outlined, 'No WhatsApp', ticket.customerPhone),
              ],
              const SizedBox(height: 10),
              _detailRow(Icons.wifi, 'Status Layanan', 'AKTIF', valueColor: _green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.developer_board_rounded, size: 18, color: _blue),
                  SizedBox(width: 8),
                  Text(
                    'Data Teknis (PPPoE / IP / Device)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFBAE6FD)),
              const SizedBox(height: 12),
              _detailRow(Icons.lan_outlined, 'IP Address', ipAddr, valueColor: _blue),
              const SizedBox(height: 10),
              _detailRow(Icons.account_circle_outlined, 'Username PPPoE', pppoeUser),
              const SizedBox(height: 10),
              _detailRow(Icons.lock_outline, 'Password PPPoE', pppoePass),
              const SizedBox(height: 10),
              _detailRow(Icons.tune_outlined, 'Profile PPPoE', pppoeProf),
              const SizedBox(height: 10),
              _detailRow(Icons.dns_outlined, 'Server OLT', oltName),
              const SizedBox(height: 10),
              _detailRow(Icons.blur_on_rounded, 'VLAN ID', vlanId),
              const SizedBox(height: 10),
              _detailRow(Icons.router_outlined, 'SN / MAC Modem', 'N/A'),
              const SizedBox(height: 10),
              _detailRow(Icons.alt_route_rounded, 'ODP / Port', 'N/A (Port: -)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 8),
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? _ink,
            ),
          ),
        ),
      ],
    );
  }
}
