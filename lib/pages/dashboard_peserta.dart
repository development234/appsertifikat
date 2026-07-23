import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'login_page.dart';
import '../pages/peserta/profil_saya.dart';
import '../pages/peserta/pendaftaran.dart';
import '../pages/peserta/jadwal_ujian.dart';
import '../pages/peserta/hasil_ujian.dart';
import '../pages/peserta/sertifikat.dart';

class DashboardPeserta extends StatefulWidget {
  const DashboardPeserta({super.key});

  @override
  State<DashboardPeserta> createState() => _DashboardPesertaState();
}

class _DashboardPesertaState extends State<DashboardPeserta> {
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  String _pesertaName = 'Peserta';
  String _pesertaStatus = 'pending';
  String _pesertaSkema = '-';

  // Data Dashboard
  Map<String, dynamic>? _jadwalTerdekat;
  Map<String, dynamic>? _hasilUjian;
  List<Map<String, dynamic>> _riwayatPendaftaran = [];
  List<Map<String, dynamic>> _notifikasi = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
    {'icon': Icons.person, 'title': 'Profil Saya', 'index': 1},
    {'icon': Icons.assignment, 'title': 'Pendaftaran', 'index': 2},
    {'icon': Icons.schedule, 'title': 'Jadwal Ujian', 'index': 3},
    {'icon': Icons.assessment, 'title': 'Hasil Ujian', 'index': 4},
    {'icon': Icons.verified, 'title': 'Sertifikat', 'index': 5},
  ];

  // ============================================================
  // LIST HALAMAN
  // ============================================================
// ============================================================
// LIST HALAMAN - PERBAIKAN
// ============================================================
late final List<Widget> _pages; // ← Gunakan late

@override
void initState() {
  super.initState();
  _pages = [
    DashboardPesertaContent(
      pesertaName: _pesertaName,
      pesertaStatus: _pesertaStatus,
      pesertaSkema: _pesertaSkema,
      jadwalTerdekat: _jadwalTerdekat,
      hasilUjian: _hasilUjian,
      riwayatPendaftaran: _riwayatPendaftaran,
      notifikasi: _notifikasi,
    ),
    const ProfilSaya(),
    const Pendaftaran(),
    const JadwalUjianPeserta(),
    const HasilUjianPeserta(),
    const SertifikatPeserta(),
  ];
  _loadDashboardData();
  _loadPesertaName();
}


  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Ambil data user
      final userData = await _supabase
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null) {
        setState(() {
          _pesertaName = userData['name'] ?? 'Peserta';
        });
      }

      // Ambil data peserta
      final pesertaData = await _supabase
          .from('peserta')
          .select('''
              nik,
              phone,
              address,
              status,
              skema_id
          ''')
          .eq('user_id', user.id)
          .maybeSingle();

      String pesertaId = '';
      if (pesertaData != null) {
        setState(() {
          _pesertaStatus = pesertaData['status'] ?? 'pending';
          _pesertaSkema = pesertaData['skema_id'] ?? '-';
          pesertaId = pesertaData['id'] ?? '';
        });
      }

      // Ambil jadwal terdekat
      if (pesertaId.isNotEmpty) {
        final jadwalData = await _supabase
            .from('pendaftaran')
            .select('''
                status,
                jadwal_id,
                jadwal (
                    tanggal,
                    waktu_mulai,
                    waktu_selesai,
                    lokasi
                )
            ''')
            .eq('peserta_id', pesertaId)
            .order('created_at', ascending: true)
            .limit(1)
            .maybeSingle();

        if (jadwalData != null) {
          final jadwal = jadwalData['jadwal'] as Map?;
          setState(() {
            _jadwalTerdekat = {
              'skema': _pesertaSkema,
              'tanggal': jadwal?['tanggal'] ?? '-',
              'waktu_mulai': jadwal?['waktu_mulai'] ?? '-',
              'waktu_selesai': jadwal?['waktu_selesai'] ?? '-',
              'lokasi': jadwal?['lokasi'] ?? '-',
              'status': jadwalData['status'] ?? 'registered',
            };
          });
        }

        // Ambil hasil ujian
        final hasilData = await _supabase
            .from('nilai')
            .select('''
                nilai_teori,
                nilai_praktik,
                status,
                catatan
            ''')
            .eq('pendaftaran.peserta_id', pesertaId)
            .maybeSingle();

        if (hasilData != null) {
          setState(() {
            _hasilUjian = {
              'skema': _pesertaSkema,
              'nilai_teori': hasilData['nilai_teori'] ?? '-',
              'nilai_praktik': hasilData['nilai_praktik'] ?? '-',
              'status': hasilData['status'] ?? 'pending',
              'catatan': hasilData['catatan'] ?? '-',
            };
          });
        }

        // Ambil riwayat pendaftaran
        final riwayatData = await _supabase
            .from('pendaftaran')
            .select('''
                status,
                tanggal_daftar,
                jadwal_id,
                jadwal (
                    tanggal,
                    waktu_mulai,
                    waktu_selesai,
                    lokasi
                )
            ''')
            .eq('peserta_id', pesertaId)
            .order('tanggal_daftar', ascending: false)
            .limit(10);

        setState(() {
          _riwayatPendaftaran = List<Map<String, dynamic>>.from(riwayatData.map((item) {
            final jadwal = item['jadwal'] as Map?;
            return {
              'skema': _pesertaSkema,
              'tanggal': jadwal?['tanggal'] ?? '-',
              'status': item['status'] ?? 'registered',
              'tanggal_daftar': item['tanggal_daftar'] ?? '',
            };
          }));
        });
      }

      // Notifikasi
      setState(() {
        _notifikasi = [
          {'title': 'Selamat datang di Aplikasi Sertifikasi BNSP!', 'time': DateTime.now().toIso8601String()},
          {'title': 'Silakan lengkapi data diri Anda.', 'time': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
        ];
        _isLoading = false;
      });
    } catch (e) {
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
  // LOAD NAMA PESERTA
  // ============================================================
  Future<void> _loadPesertaName() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userData = await _supabase
            .from('users')
            .select('name, email')
            .eq('id', user.id)
            .maybeSingle();
        if (userData != null && mounted) {
          setState(() {
            _pesertaName = userData['name'] ?? 'Peserta';
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ============================================================
  // NAVIGASI
  // ============================================================
  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  // ============================================================
  // TOGGLE SIDEBAR
  // ============================================================
  void _toggleSidebar() {
    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
  }

  // ============================================================
  // BUILD SIDEBAR - DESKTOP
  // ============================================================
  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarExpanded ? 200.0 : 60.0;

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // HEADER
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[800]!],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: _isSidebarExpanded ? 20 : 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _pesertaName.isNotEmpty ? _pesertaName[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: _isSidebarExpanded ? 16 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pesertaName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Peserta',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // TOGGLE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[600],
                ),
                onPressed: _toggleSidebar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          const Divider(height: 1),

          // MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ..._menuItems.map((item) {
                  final index = _menuItems.indexOf(item);
                  final isSelected = _selectedIndex == index;
                  return _buildSidebarTile(
                    icon: item['icon'],
                    title: item['title'],
                    isActive: isSelected,
                    onTap: () => _navigateTo(index),
                  );
                }),
                const Spacer(),
                _buildSidebarTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final iconColor = isActive ? Colors.green : (color ?? Colors.grey[600]);
    final textColor = isActive ? Colors.green : (color ?? Colors.grey[700]);
    final bgColor = isActive ? Colors.green.withValues(alpha: 0.08) : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD DRAWER - MOBILE
  // ============================================================
  Widget _buildDrawer() {
    return Drawer(
      width: 240,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[800]!],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      _pesertaName.isNotEmpty ? _pesertaName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pesertaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Peserta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._menuItems.map((item) {
              final index = _menuItems.indexOf(item);
              final isSelected = _selectedIndex == index;
              return _buildDrawerTile(
                icon: item['icon'],
                title: item['title'],
                isActive: isSelected,
                onTap: () {
                  Navigator.pop(context);
                  _navigateTo(index);
                },
              );
            }),
            const Divider(),
            _buildDrawerTile(
              icon: Icons.logout,
              title: 'Logout',
              color: Colors.red,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    final iconColor = isActive ? Colors.green : (color ?? Colors.grey[600]);
    final textColor = isActive ? Colors.green : (color ?? Colors.grey[700]);
    final bgColor = isActive ? Colors.green.withValues(alpha: 0.08) : Colors.transparent;

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      visualDensity: VisualDensity.compact,
      tileColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Update pages dengan data terbaru
    _pages[0] = DashboardPesertaContent(
      key: const ValueKey('dashboard'),
      pesertaName: _pesertaName,
      pesertaStatus: _pesertaStatus,
      pesertaSkema: _pesertaSkema,
      jadwalTerdekat: _jadwalTerdekat,
      hasilUjian: _hasilUjian,
      riwayatPendaftaran: _riwayatPendaftaran,
      notifikasi: _notifikasi,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      // ... 
      body: _isLoading && _selectedIndex == 0
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 12),
                  Text('Memuat data...'),
                ],
              ),
            )
          : Row(
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F7FA),
                    child: IndexedStack( // ← Ganti dengan IndexedStack
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
    );
  }


}

// ============================================================
// DASHBOARD PESERTA CONTENT
// ============================================================
class DashboardPesertaContent extends StatelessWidget {
  final String pesertaName;
  final String pesertaStatus;
  final String pesertaSkema;
  final Map<String, dynamic>? jadwalTerdekat;
  final Map<String, dynamic>? hasilUjian;
  final List<Map<String, dynamic>> riwayatPendaftaran;
  final List<Map<String, dynamic>> notifikasi;

  const DashboardPesertaContent({
    super.key, // ← Tambahkan super.key
    required this.pesertaName,
    required this.pesertaStatus,
    required this.pesertaSkema,
    this.jadwalTerdekat,
    this.hasilUjian,
    required this.riwayatPendaftaran,
    required this.notifikasi,
  });

  // ============================================================
  // GET STATUS
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
        return '⏳ Pending';
      case 'verifikasi':
        return '📋 Verifikasi';
      case 'tidak_lulus':
        return '❌ Tidak Lulus';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '-';
    try {
      final time = DateTime.parse('2024-01-01T$timeString');
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB';
    } catch (e) {
      return timeString;
    }
  }

  String _formatDateTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays} hari lalu';
      if (diff.inHours > 0) return '${diff.inHours} jam lalu';
      if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
      return 'Baru saja';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WELCOME
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Selamat datang, $pesertaName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 0),
              Text(
                'Kelola sertifikasi BNSP Anda dengan mudah',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 2,
                width: 600,
                color: const Color.fromARGB(255, 4, 211, 238),
              ),
            ],
            
          ),
          const SizedBox(height: 24),

          // STATUS CARD
          Card(
            elevation: 2,
            shadowColor: _getStatusColor(pesertaStatus).withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(pesertaStatus).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      pesertaStatus == 'lulus'
                          ? Icons.check_circle
                          : pesertaStatus == 'pending'
                              ? Icons.pending
                              : Icons.info,
                      color: _getStatusColor(pesertaStatus),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Pendaftaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _getStatusText(pesertaStatus),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(pesertaStatus),
                          ),
                        ),
                        Text(
                          'Skema: ${pesertaSkema != '-' ? pesertaSkema : 'Belum memilih skema'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
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

          // QUICK ACTION
          Text(
            '⚡ Aksi Cepat',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.assignment_add,
                  label: 'Daftar',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.upload_file,
                  label: 'Upload',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.picture_as_pdf,
                  label: 'Sertifikat',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // JADWAL & HASIL - 2 KOLOM
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // JADWAL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Jadwal Terdekat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: jadwalTerdekat != null && jadwalTerdekat?['tanggal'] != '-'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jadwalTerdekat?['skema'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(_formatDate(jadwalTerdekat?['tanggal'])),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text('${_formatTime(jadwalTerdekat?['waktu_mulai'])} - ${_formatTime(jadwalTerdekat?['waktu_selesai'])}'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(jadwalTerdekat?['lokasi'] ?? '-'),
                                    ],
                                  ),
                                ],
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'Belum ada jadwal',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // HASIL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Hasil Ujian',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: hasilUjian != null && hasilUjian?['nilai_teori'] != '-'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasilUjian?['skema'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Teori', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            Text(
                                              hasilUjian?['nilai_teori']?.toString() ?? '-',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Praktik', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            Text(
                                              hasilUjian?['nilai_praktik']?.toString() ?? '-',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Status', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            Text(
                                              hasilUjian?['status'] == 'lulus' ? '✅ Lulus' : '⏳ Pending',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(hasilUjian?['status'] ?? 'pending'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    'Belum ada hasil',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // NOTIFIKASI
          Text(
            '🔔 Notifikasi',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: notifikasi.isNotEmpty
                ? Column(
                    children: notifikasi.map((notif) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notif['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTimeAgo(notif['time']),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Tidak ada notifikasi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}