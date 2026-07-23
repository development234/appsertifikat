import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../config/supabase_config.dart';

class ProfilSaya extends StatefulWidget {
  const ProfilSaya({super.key});

  @override
  State<ProfilSaya> createState() => _ProfilSayaState();
}

class _ProfilSayaState extends State<ProfilSaya> {
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _pesertaData = {};
  Map<String, dynamic> _skemaData = {};

  @override
  void initState() {
    super.initState();
    _loadProfilData();
  }

  // ============================================================
  // LOAD PROFIL DATA - PERBAIKAN
  // ============================================================
  Future<void> _loadProfilData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      print('🔍 User ID: ${user.id}'); // Debug

      // Ambil data user
      final userData = await _supabase
          .from('users')
          .select('id, email, name, role, created_at')
          .eq('id', user.id)
          .maybeSingle();

      print('📋 User Data: $userData'); // Debug

      // Ambil data peserta
      final pesertaData = await _supabase
          .from('peserta')
          .select('''
              id,
              nik,
              phone,
              address,
              birth_date,
              status,
              skema_id,
              dokumen_ktp,
              dokumen_ijazah,
              dokumen_skor,
              created_at
          ''')
          .eq('user_id', user.id)
          .maybeSingle();

      print('📋 Peserta Data: $pesertaData'); // Debug

      // Ambil data skema
      Map<String, dynamic> skemaData = {};
      if (pesertaData != null && pesertaData['skema_id'] != null) {
        final skemaResult = await _supabase
            .from('skema')
            .select('id, name, code, description, durasi')
            .eq('id', pesertaData['skema_id'])
            .maybeSingle();
        if (skemaResult != null) {
          skemaData = skemaResult;
        }
      }

      print('📋 Skema Data: $skemaData'); // Debug

      setState(() {
        _userData = userData ?? {};
        _pesertaData = pesertaData ?? {};
        _skemaData = skemaData;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e'); // Debug
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  // ============================================================
  // GET STATUS COLOR
  // ============================================================
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lulus':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'verifikasi':
        return Colors.blue;
      case 'tidak_lulus':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'lulus':
        return '✅ Lulus';
      case 'pending':
        return '⏳ Menunggu Verifikasi';
      case 'verifikasi':
        return '📋 Dalam Verifikasi';
      case 'tidak_lulus':
        return '❌ Tidak Lulus';
      default:
        return status;
    }
  }

  // ============================================================
  // BUILD INFO ROW
  // ============================================================
  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD DOKUMEN STATUS
  // ============================================================
  Widget _buildDokumenStatus(String label, String? url) {
    final isUploaded = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green.withOpacity(0.08) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUploaded ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.upload_file,
            size: 16,
            color: isUploaded ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isUploaded ? Colors.green[700] : Colors.grey[600],
              fontWeight: isUploaded ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (isUploaded) ...[
            const SizedBox(width: 4),
            Text(
              '✅',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final name = _userData['name'] ?? '-';
    final email = _userData['email'] ?? '-';
    final role = _userData['role'] ?? '-';
    final createdAt = _userData['created_at'] ?? '';

    final nik = _pesertaData['nik'] ?? '-';
    final phone = _pesertaData['phone'] ?? '-';
    final address = _pesertaData['address'] ?? '-';
    final birthDate = _pesertaData['birth_date'] ?? '-';
    final status = _pesertaData['status'] ?? 'pending';
    final skemaId = _pesertaData['skema_id'] ?? '-';

    final skemaName = _skemaData['name'] ?? '-';
    final skemaCode = _skemaData['code'] ?? '-';
    final skemaDurasi = _skemaData['durasi'] ?? '-';

    final dokumenKtp = _pesertaData['dokumen_ktp'] as String?;
    final dokumenIjazah = _pesertaData['dokumen_ijazah'] as String?;
    final dokumenSkor = _pesertaData['dokumen_skor'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 12),
                  Text('Memuat data profil...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER
                  // ============================================
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // TITLE
                  // ============================================
                  const Text(
                    '📋 Informasi Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ============================================
                  // CARD PROFIL
                  // ============================================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('Nama Lengkap', name, icon: Icons.person),
                          _buildInfoRow('Email', email, icon: Icons.email),
                          _buildInfoRow('Role', role, icon: Icons.assignment_ind),
                          _buildInfoRow('NIK', nik, icon: Icons.credit_card),
                          _buildInfoRow('No. HP', phone, icon: Icons.phone),
                          _buildInfoRow('Tanggal Lahir', _formatDate(birthDate), icon: Icons.cake),
                          _buildInfoRow('Alamat', address, icon: Icons.home),
                          _buildInfoRow('Skema', skemaName, icon: Icons.category),
                          _buildInfoRow('Kode Skema', skemaCode, icon: Icons.code),
                          _buildInfoRow('Durasi Ujian', skemaDurasi != '-' ? '$skemaDurasi menit' : '-', icon: Icons.timer),
                          _buildInfoRow('Status', _getStatusText(status), icon: Icons.info),
                          _buildInfoRow('Bergabung Sejak', _formatDateTime(createdAt), icon: Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // DOKUMEN
                  // ============================================
                  const Text(
                    '📎 Dokumen Sertifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildDokumenStatus('KTP', dokumenKtp),
                              _buildDokumenStatus('Ijazah', dokumenIjazah),
                              _buildDokumenStatus('Skor', dokumenSkor),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dokumen yang telah diupload akan diverifikasi oleh admin.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // AKTIVITAS AKUN
                  // ============================================
                  const Text(
                    '🔐 Aktivitas Akun',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                            title: const Text(
                              'Ganti Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Ubah password akun Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_outline,
                                color: Colors.orange,
                                size: 18,
                              ),
                            ),
                            title: const Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Perbarui data diri Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}