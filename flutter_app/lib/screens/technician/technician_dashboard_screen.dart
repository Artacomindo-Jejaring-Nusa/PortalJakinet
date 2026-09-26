import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/technician_provider.dart';
import 'tickets_tab.dart';
import 'technician_profile_tab.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
const _blue = Color(0xFF2563EB);
const _red = Color(0xFFDC2626);

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TicketsTab(),
    TechnicianProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TechnicianProvider>(
        context,
        listen: false,
      ).refreshData(showLoading: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final techProvider = context.watch<TechnicianProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            _DashboardHeader(
              onRefresh: () => techProvider.refreshData(showLoading: true),
            ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _tabs),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onSelected: (index) => setState(() => _currentIndex = index),
          ticketCount: techProvider.activeTicketCount,
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal Petugas Teknisi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'jpo.jelantik.com Field Operations',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  backgroundColor: const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Muat ulang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onSelected,
    required this.ticketCount,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final int ticketCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.confirmation_number_outlined,
                  selectedIcon: Icons.confirmation_number,
                  label: 'Tiket Gangguan',
                  accent: _red,
                  selected: currentIndex == 0,
                  badgeCount: ticketCount,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profil',
                  accent: _blue,
                  selected: currentIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color accent;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    color: selected ? accent : _muted,
                    size: 24,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _ink : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
