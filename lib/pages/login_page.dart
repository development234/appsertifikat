import 'package:appsertifikat/pages/dashboard_admin.dart';
import 'package:appsertifikat/pages/dashboard_pakar.dart';
import 'package:appsertifikat/pages/dashboard_peserta.dart';
import 'package:appsertifikat/pages/register_page.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  int _loginAttempts = 0;
  bool _isLocked = false;

  // ============================================================
  // DATA QUICK LOGIN
  // ============================================================
  final List<Map<String, dynamic>> _quickLoginData = [
    {
      'role': 'Admin',
      'email': 'admin@tester.com',
      'password': 'admin123',
      'icon': Icons.admin_panel_settings,
      'color': const Color(0xFF6C63FF),
      'bgColor': const Color(0xFFEEF2FF),
    },
    {
      'role': 'Pakar',
      'email': 'pakar@tester.com',
      'password': 'pakar123',
      'icon': Icons.school,
      'color': const Color(0xFFFF6B6B),
      'bgColor': const Color(0xFFFFEEEE),
    },
    {
      'role': 'Peserta',
      'email': 'peserta@tester.com',
      'password': 'user123',
      'icon': Icons.person,
      'color': const Color(0xFF4ECDC4),
      'bgColor': const Color(0xFFEEFFFF),
    },
    {
      'role': 'Supri',
      'email': 'supri@lpk.com',
      'password': 'supri123',
      'icon': Icons.person_outline,
      'color': const Color(0xFFFF9F43),
      'bgColor': const Color(0xFFFFF3E8),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    // Implementasi jika ingin menyimpan session
  }

  // ============================================================
  // VALIDASI
  // ============================================================
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

// ============================================================
// HANDLE LOGIN
// ============================================================
Future<void> _handleLogin({String? email, String? password}) async {
  final loginEmail = email ?? _emailController.text;
  final loginPassword = password ?? _passwordController.text;

  print('🔐 Login dengan email: $loginEmail'); // Debug

  if (loginEmail.isEmpty || loginPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email dan password harus diisi!'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_isLocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Akun terkunci. Coba lagi dalam 5 menit.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final result = await _authService.login(
      email: loginEmail,
      password: loginPassword,
    );

    print('📋 Result: $result'); // Debug

    if (result['success']) {
      _loginAttempts = 0;
      final role = result['role'] ?? 'peserta';
      final name = result['name'] ?? 'Pengguna';

      print('✅ Login berhasil! Role: $role, Name: $name'); // Debug

      if (!mounted) return;

      Widget destination;
      switch (role) {
        case 'admin':
          destination = const DashboardAdmin();
          break;
        case 'pakar':
          destination = const DashboardPakar();
          break;
        case 'peserta':
          destination = const DashboardPeserta();
          break;
        default:
          destination = const DashboardPeserta();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selamat datang, $name! 👋'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _loginAttempts++;
      print('❌ Login gagal: ${result['message']}'); // Debug
      
      if (_loginAttempts >= 3) {
        setState(() => _isLocked = true);
        Future.delayed(const Duration(minutes: 5), () {
          if (mounted) setState(() {
            _isLocked = false;
            _loginAttempts = 0;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terlalu banyak percobaan gagal. Coba lagi dalam 5 menit.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('❌ Error: $e'); // Debug
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  // ============================================================
  // QUICK LOGIN BUTTON
  // ============================================================
  Widget _buildQuickLoginButton(Map<String, dynamic> data) {
    return Expanded(
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                // Isi email dan password otomatis
                _emailController.text = data['email'];
                _passwordController.text = data['password'];
                
                // Langsung login
                _handleLogin(
                  email: data['email'],
                  password: data['password'],
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: data['bgColor'],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: data['color'].withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data['icon'],
                color: data['color'],
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                data['role'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: data['color'],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data['email'],
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  } 
    
  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 12,
            shadowColor: Colors.purple.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ============================================
                      // LOGO & TITLE
                      // ============================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[100]!,
                              Colors.blue[100]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_outlined,
                                size: 48,
                                color: Colors.purple[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sertifikasi BNSP',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'LPK Pabrik Cerdas Commit',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ============================================
                      // QUICK LOGIN BUTTONS
                      // ============================================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚡ Login Cepat',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: _quickLoginData
                                  .map((data) => _buildQuickLoginButton(data))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ============================================
                      // DIVIDER
                      // ============================================
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'atau login manual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ============================================
                      // FIELD EMAIL
                      // ============================================
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan email Anda',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.purple[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[400]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 16),

                      // ============================================
                      // FIELD PASSWORD
                      // ============================================
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password Anda',
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                            color: Colors.purple[400],
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[500],
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.purple[400]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: _validatePassword,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),

                      // ============================================
                      // REMEMBER ME & FORGOT PASSWORD
                      // ============================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(
                                  () => _rememberMe = value ?? false,
                                ),
                                activeColor: Colors.purple[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Text(
                                'Ingat Saya',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigasi ke lupa password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.purple[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ============================================
                      // BUTTON LOGIN
                      // ============================================
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.purple[700],
                          elevation: 3,
                          shadowColor: Colors.purple.withValues(alpha: 0.3),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ============================================
                      // LINK REGISTER
                      // ============================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              ' Daftar di sini',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ============================================
                      // FOOTER
                      // ============================================
                      Center(
                        child: Text(
                          '© 2026 LPK Pabrik Cerdas Commit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}