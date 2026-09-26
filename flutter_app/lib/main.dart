import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/customer_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/technician_provider.dart';
import 'config/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/technician/technician_dashboard_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase Core
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase.initializeApp error: $e');
  }

  // Lock app orientation strictly to Portrait (No Auto-Rotate)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize date formatting for Indonesia locale
  await initializeDateFormatting('id_ID', null);
  
  // Initialize FCM Service for Push Notifications
  try {
    await FCMService().initialize();
  } catch (e) {
    print('FCMService initialize error: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
      ],
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
      title: 'Portal Ajnusa',
      theme: activeTheme,
      debugShowCheckedModeBanner: false,
      home: _getHomeScreen(context),
    );
  }

  Widget _getHomeScreen(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final technicianProvider = context.watch<TechnicianProvider>();

    // Only display full-screen loading on initial startup initialization
    if (!customerProvider.isInitialized || !technicianProvider.isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: customerProvider.isJelantik ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
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

    if (technicianProvider.technicianUser != null) {
      return const TechnicianDashboardScreen();
    }

    if (customerProvider.customerData != null) {
      return const DashboardScreen();
    }

    return const LoginScreen();
  }
}

