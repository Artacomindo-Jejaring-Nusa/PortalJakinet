import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/technician_provider.dart';
import '../../models/installation_task.dart';

class InstallationTab extends StatefulWidget {
  const InstallationTab({super.key});

  @override
  State<InstallationTab> createState() => _InstallationTabState();
}

class _InstallationTabState extends State<InstallationTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openWhatsApp(String phone, String name) async {
    var cleaned = phone.replaceAll(RegExp(r'[-\s]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('+62')) {
      cleaned = cleaned.substring(1);
    }
    
    final uri = Uri.parse('https://wa.me/$cleaned?text=Halo%20$name,%20saya%20teknisi%20Jelantik/Jakinet%20mengenai%20jadwal%20pemasangan%20internet.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStatusDialog(BuildContext context, InstallationTask task) {
    final provider = Provider.of<TechnicianProvider>(context, listen: false);
    String selectedStatus = task.status;
    final notesController = TextEditingController(text: task.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.engineering, color: Color(0xFF2563EB), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Status Instalasi Baru',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelanggan: ${task.customerName}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Paket: ${task.packageName} • ${task.phone.isNotEmpty ? task.phone : "No WA Not Available"}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Pilih Status Pemasangan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _statusChip('Belum Terpasang', selectedStatus, (val) => setModalState(() => selectedStatus = val)),
                      _statusChip('Proses Pemasangan', selectedStatus, (val) => setModalState(() => selectedStatus = val)),
                      _statusChip('Selesai Terpasang', selectedStatus, (val) => setModalState(() => selectedStatus = val)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Catatan Teknis Pemasangan (ODP / Port / Modem)',
                      hintText: 'Contoh: Terpasang ODP-NAG-02 Port 3, Modem HG8245H SN: 48575443...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await provider.updateInstallationStatus(
                          task.id,
                          selectedStatus,
                          notesController.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Status instalasi berhasil diperbarui' : 'Gagal memperbarui status'),
                              backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      label: const Text('Simpan & Update Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
      onSelected: (_) => onSelect(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianProvider>();
    var tasks = provider.filteredInstallations;

    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((t) {
        final query = _searchQuery.toLowerCase();
        return t.customerName.toLowerCase().contains(query) ||
            t.address.toLowerCase().contains(query) ||
            t.phone.contains(query);
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshData(),
      child: Column(
        children: [
          // Header Search & Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari Nama Pelanggan, Alamat, atau No WA...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterBadge(provider, 'Aktif (${provider.activeInstallationCount})', 'Semua'),
                      _buildFilterBadge(provider, 'Belum Terpasang', 'Pending'),
                      _buildFilterBadge(provider, 'Proses Pemasangan', 'On Progress'),
                      _buildFilterBadge(provider, 'Selesai Terpasang', 'Selesai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: provider.isLoading && tasks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada antrian pemasangan baru',
                              style: TextStyle(fontSize: 16, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Semua instalasi pelanggan baru telah selesai terpasang.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _buildInstallationCard(context, task);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(TechnicianProvider provider, String label, String value) {
    final isSelected = provider.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => provider.setStatusFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstallationCard(BuildContext context, InstallationTask task) {
    final st = task.status.toLowerCase();

    Color statusBg = const Color(0xFFFEF3C7);
    Color statusText = const Color(0xFFD97706);
    String statusLabel = 'BELUM TERPASANG';

    if (st.contains('proses') || st.contains('progress') || st.contains('dalam')) {
      statusBg = const Color(0xFFEFF6FF);
      statusText = const Color(0xFF2563EB);
      statusLabel = 'PROSES PEMASANGAN';
    } else if (st.contains('selesai') || st.contains('installed') || st.contains('aktif')) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
      statusLabel = 'SELESAI TERPASANG';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusText, width: 5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Package and Status Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        task.packageName,
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusText, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Customer Name
                Text(
                  task.customerName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2),
                ),
                const SizedBox(height: 8),

                // Customer Address & Contact Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              task.address,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      if (task.phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone_android_outlined, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              task.phone,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    if (task.phone.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _openWhatsApp(task.phone, task.customerName),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('WA Pelanggan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (task.phone.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showStatusDialog(context, task),
                        icon: const Icon(Icons.edit_note_outlined, size: 18),
                        label: const Text('Update Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
