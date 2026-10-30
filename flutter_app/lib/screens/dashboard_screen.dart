import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/chat_provider.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'pesan_tab.dart';
import 'settings_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<HomeTabState> _homeKey = GlobalKey<HomeTabState>();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = [
      HomeTab(key: _homeKey),
      const HistoryTab(),
      const PesanTab(),
      const SettingsTab(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatIfPossible();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat aplikasi dibuka kembali dari background/keluar, otomatis sinkronkan ulang pesan & reconnect socket
      _initChatIfPossible(forceRefresh: true);
    }
  }

  void _initChatIfPossible({bool forceRefresh = false}) {
    final custProvider = context.read<CustomerProvider>();
    final chatProvider = context.read<ChatProvider>();
    if (custProvider.customerData != null) {
      final p = custProvider.customerData!.pelanggan;
      if (forceRefresh) {
        chatProvider.fetchHistory(silent: true);
      }
      chatProvider.initChat(
        pelangganId: p.id,
        brand: custProvider.isJelantik ? 'Jelantik' : 'Jakinet',
        name: p.nama.isNotEmpty ? p.nama : 'Pelanggan',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(provider.brandLogo),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.brandTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  'Customer Portal',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Tutorial / Panduan Button
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Panduan Aplikasi',
            onPressed: () {
              if (_currentIndex != 0) {
                setState(() => _currentIndex = 0);
              }
              Future.delayed(const Duration(milliseconds: 300), () {
                _homeKey.currentState?.showTutorial();
              });
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF64748B),
            ),
            tooltip: 'Keluar',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Keluar Akun',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari portal pelanggan?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await provider.logout();
                      },
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            RefreshIndicator(
              onRefresh: provider.refresh,
              child: _tabs[0],
            ),
            RefreshIndicator(
              onRefresh: provider.refresh,
              child: _tabs[1],
            ),
            _tabs[2], // PesanTab: state chat, input, scroll selalu terjaga
            RefreshIndicator(
              onRefresh: provider.refresh,
              child: _tabs[3],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          context.read<ChatProvider>().setChatTabActive(index == 2);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: themeColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message_rounded),
            label: 'Pesan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
