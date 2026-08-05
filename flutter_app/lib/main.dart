import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/customer_provider.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for Indonesia locale
  await initializeDateFormatting('id_ID', null);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => CustomerProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final isJelantik = provider.isJelantik;
    
    // Choose theme dynamically based on customer's brand
    final activeTheme = isJelantik ? AppTheme.jelantikTheme : AppTheme.jakinetTheme;

    return MaterialApp(
      title: 'Portal Pelanggan',
      theme: activeTheme,
      debugShowCheckedModeBanner: false,
      home: _getHomeScreen(provider),
    );
  }

  Widget _getHomeScreen(CustomerProvider provider) {
    if (provider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: provider.isJelantik ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              const Text(
                'Memuat Portal...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.customerData != null) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}
