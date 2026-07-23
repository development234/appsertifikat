import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final supabase = SupabaseConfig.client;

  // ============================================================
  // LOGIN
  // ============================================================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Trim email untuk menghilangkan spasi
      final trimmedEmail = email.trim();
      
      print('🔐 Mencoba login: $trimmedEmail'); // Debug

      final response = await supabase.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      print('✅ Response user: ${response.user?.email}'); // Debug

      if (response.user != null) {
        // Ambil data user dari tabel users
        final userData = await supabase
            .from('users')
            .select('role, name')
            .eq('id', response.user!.id)
            .maybeSingle();

        print('📋 User data: $userData'); // Debug

        // Jika user tidak ada di tabel users, buat otomatis
        if (userData == null) {
          print('⚠️ User tidak ditemukan di tabel users, membuat otomatis...');
          
          // Ambil data dari auth.users
          final authUserData = await supabase
              .from('auth.users')
              .select('raw_user_meta_data')
              .eq('id', response.user!.id)
              .maybeSingle();
          
          final metaData = authUserData?['raw_user_meta_data'] ?? {};
          final userName = metaData['name'] ?? 'Pengguna';
          final userRole = metaData['role'] ?? 'peserta';
          
          // Insert ke tabel users
          await supabase.from('users').insert({
            'id': response.user!.id,
            'email': trimmedEmail,
            'name': userName,
            'role': userRole,
          });
          
          return {
            'success': true,
            'message': 'Login berhasil',
            'user': response.user,
            'role': userRole,
            'name': userName,
          };
        }

        return {
          'success': true,
          'message': 'Login berhasil',
          'user': response.user,
          'role': userData['role'] ?? 'peserta',
          'name': userData['name'] ?? 'Pengguna',
        };
      }

      return {'success': false, 'message': 'Login gagal'};
    } catch (e) {
      print('❌ Error login: $e'); // Debug
      
      if (e.toString().contains('Invalid login credentials')) {
        return {'success': false, 'message': 'Email atau password salah'};
      } else if (e.toString().contains('Email not confirmed')) {
        return {'success': false, 'message': 'Silakan verifikasi email terlebih dahulu'};
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final trimmedEmail = email.trim();

      // Cek apakah email sudah terdaftar di tabel users
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (existingUser != null) {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }

      // Register ke Supabase Auth
      final authResponse = await supabase.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {
          'name': name.trim(),
          'role': role,
        },
      );

      if (authResponse.user != null) {
        // Insert ke tabel users
        await supabase.from('users').insert({
          'id': authResponse.user!.id,
          'email': trimmedEmail,
          'name': name.trim(),
          'role': role,
        });

        // Jika role = peserta, buat record di tabel peserta
        if (role == 'peserta') {
          await supabase.from('peserta').insert({
            'user_id': authResponse.user!.id,
            'nik': '0000000000000000',
            'phone': '',
            'address': '',
            'birth_date': null,
            'status': 'pending',
          });
        }

        return {
          'success': true,
          'message': 'Registrasi berhasil! Silakan login.',
        };
      }

      return {'success': false, 'message': 'Registrasi gagal'};
    } catch (e) {
      if (e.toString().contains('User already registered')) {
        return {'success': false, 'message': 'Email sudah terdaftar'};
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ============================================================
  // CEK SESSION
  // ============================================================
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  // ============================================================
  // AMBIL USER SAAT INI
  // ============================================================
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // ============================================================
  // AMBIL ROLE USER
  // ============================================================
  Future<String?> getUserRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final userData = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return userData?['role'] as String?;
    } catch (e) {
      return null;
    }
  }
}