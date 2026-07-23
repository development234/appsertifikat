import 'package:appsertifikat/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:appsertifikat/config/supabase_config.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Supabase
  await SupabaseConfig.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sertifikasi BNSP - LPK Pabrik Cerdas Commit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}