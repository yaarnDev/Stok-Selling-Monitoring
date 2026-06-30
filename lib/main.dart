import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Wajib ditambahkan untuk membaca kIsWeb
import 'screens/audience_screen.dart'; // Memastikan import mengarah ke file home screen yang benar
import 'admin/providers/admin_provider.dart';
import 'admin/pages/dashboard.dart';
import 'firebase_options.dart';

// Test mode flag removed; admin access requires real Firebase auth

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("⚠️ Firebase initialization failed: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring AMDK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: const AudienceHomeScreen(), // Membuka halaman pantau stok mewah kita
      routes: {
        '/admin': (ctx) => const AdminDashboardPage(),
      },
    );
  }
}