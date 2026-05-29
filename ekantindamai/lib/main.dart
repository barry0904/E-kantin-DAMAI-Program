import 'dart:io'; // TAMBAHAN 1: Wajib di-import untuk menggunakan HttpClient
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth.dart'; // Pastikan file auth.dart Anda tidak dihapus

// TAMBAHAN 2: Class untuk mengabaikan error SSL/Sertifikat pada gambar URL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TAMBAHAN 3: Daftarkan pengaturan HTTP sebelum aplikasi berjalan
  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAC6ibvEFXEs5dppLar61IXQs8msg4pLk0",
      appId: "1:831340702711:android:8fcef0efac9e481c0cdcf2",
      messagingSenderId: "831340702711",
      projectId: "ekantin-app-c8c3a",
      storageBucket: "ekantin-app-c8c3a.firebasestorage.app",
    ),
  );
  runApp(const SekolahDamaiApp());
}

// Global List untuk menyimpan data keranjang sementara
List<Map<String, dynamic>> globalCart = [];

class DamaiTheme {
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF90CAF9);
}

class SekolahDamaiApp extends StatelessWidget {
  const SekolahDamaiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantin Sekolah Damai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: DamaiTheme.primaryColor,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: DamaiTheme.primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DamaiTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}