import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/customer_provider.dart';
import '../login_screen.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _red = Color(0xFFDC2626);
const _green = Color(0xFF16A34A);

class TechnicianProfileTab extends StatelessWidget {
  const TechnicianProfileTab({super.key});

  void _handleLogout(BuildContext context) async {
    final techProvider = Provider.of<TechnicianProvider>(
      context,
      listen: false,
    );
    final custProvider = Provider.of<CustomerProvider>(context, listen: false);

    techProvider.clear();
    await custProvider.logout();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final techProvider = context.watch<TechnicianProvider>();
    final user = techProvider.technicianUser;

    final activeTicketCount = techProvider.activeTicketCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeader(
            initial: (user?.name.isNotEmpty == true ? user!.name[0] : 'T')
                .toUpperCase(),
            name: user?.name ?? 'Petugas Teknisi',
            contact: user?.email ?? user?.whatsapp ?? 'Teknisi Lapangan',
            role: 'Role: ${user?.role ?? "Teknisi"}',
            id: 'ID: ${user?.id ?? "25"}',
          ),

          const SizedBox(height: 36),
          const _SectionTitle('Statistik Tugas Lapangan'),
          _Panel(
            child: _StatCell(
              title: 'Tiket Gangguan Aktif (Membutuhkan Penanganan)',
              value: activeTicketCount.toString(),
              dotColor: _red,
            ),
          ),

          const SizedBox(height: 36),
          const _SectionTitle('Pengaturan & Sesi'),
          _Panel(
            child: Column(
              children: [
                _SettingRow(
                  title: 'Refresh Data Lapangan',
                  subtitle: 'Sinkronisasi ulang dari jpo.jelantik.com',
                  onTap: () async {
                    await techProvider.refreshData(showLoading: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: const Text(
                            'Data berhasil diperbarui dari portal server',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, thickness: 1, color: _line),
                _SettingRow(
                  title: 'Keluar dari Akun Teknisi',
                  titleColor: _red,
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initial,
    required this.name,
    required this.contact,
    required this.role,
    required this.id,
  });

  final String initial;
  final String name;
  final String contact;
  final String role;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(label: role, dotColor: _green),
            _Tag(label: id),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.dotColor});

  final String label;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: _ink,
        ),
      ),
    );
  }
}

/// White surface with a hairline border. Clips children so ink ripples
/// respect the rounded corners.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _line),
        ),
        child: child,
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.title,
    required this.value,
    required this.dotColor,
  });

  final String title;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 44,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: _ink,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor = _ink,
  });

  final String title;
  final String? subtitle;
  final Color titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
