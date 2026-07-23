import 'package:appsertifikat/pages/pakar/daftar_peserta.dart';
import 'package:appsertifikat/pages/pakar/input_nilai.dart';
import 'package:appsertifikat/pages/pakar/jadwal_ujian.dart';
import 'package:appsertifikat/pages/pakar/riwayat_penilaian.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'login_page.dart';


class DashboardPakar extends StatefulWidget {
  const DashboardPakar({super.key});

  @override
  State<DashboardPakar> createState() => _DashboardPakarState();
}

class _DashboardPakarState extends State<DashboardPakar> {
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  String _pakarName = 'Pakar';

  // Data Dashboard
  int _totalJadwal = 0;
  int _totalPeserta = 0;
  int _totalDinilai = 0;
  int _totalPending = 0;

  List<Map<String, dynamic>> _jadwalList = [];
  List<Map<String, dynamic>> _pesertaList = [];
  List<Map<String, dynamic>> _recentActivities = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
    {'icon': Icons.schedule, 'title': 'Jadwal Ujian', 'index': 1},
    {'icon': Icons.people, 'title': 'Daftar Peserta', 'index': 2},
    {'icon': Icons.assessment, 'title': 'Input Nilai', 'index': 3},
    {'icon': Icons.history, 'title': 'Riwayat Penilaian', 'index': 4},
  ];

  // ============================================================
  // LIST HALAMAN
  // ============================================================
  final List<Widget> _pages = [
    DashboardPakarContent(
      totalJadwal: 0,
      totalPeserta: 0,
      totalDinilai: 0,
      totalPending: 0,
      jadwalList: [],
      pesertaList: [],
      recentActivities: [],
      pakarName: 'Pakar',
    ),
    JadwalUjian(),
    DaftarPeserta(),
    InputNilai(),
    RiwayatPenilaian(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadPakarName();
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

      // Ambil jadwal
      final jadwalData = await _supabase
          .from('jadwal')
          .select('''
              id,
              tanggal,
              waktu_mulai,
              waktu_selesai,
              lokasi,
              status,
              skema!inner (
                  name,
                  code
              )
          ''')
          .eq('pakar_id', user.id)
          .order('tanggal', ascending: true);

      setState(() {
        _jadwalList = List<Map<String, dynamic>>.from(jadwalData);
        _totalJadwal = jadwalData.length;
      });

      // Hitung statistik
      int totalPeserta = 0;
      int totalPending = 0;
      int totalDinilai = 0;

      for (var jadwal in jadwalData) {
        final jadwalId = jadwal['id'];

        final pesertaCount = await _supabase
            .from('pendaftaran')
            .select('id')
            .eq('jadwal_id', jadwalId);
        totalPeserta += pesertaCount.length;

        final pendingData = await _supabase
            .from('pendaftaran')
            .select('''
                id,
                nilai!inner (
                    status
                )
            ''')
            .eq('jadwal_id', jadwalId)
            .eq('nilai.status', 'pending');
        totalPending += pendingData.length;

        final dinilaiData = await _supabase
            .from('pendaftaran')
            .select('''
                id,
                nilai!inner (
                    status
                )
            ''')
            .eq('jadwal_id', jadwalId)
            .neq('nilai.status', 'pending');
        totalDinilai += dinilaiData.length;
      }

      // Peserta perlu dinilai
      final pesertaData = await _supabase
          .from('pendaftaran')
          .select('''
              id,
              status,
              peserta!inner (
                  nik,
                  users!inner (
                      name,
                      email
                  )
              ),
              jadwal!inner (
                  tanggal,
                  skema!inner (
                      name
                  )
              ),
              nilai!inner (
                  status,
                  nilai_teori,
                  nilai_praktik
              )
          ''')
          .eq('nilai.status', 'pending')
          .limit(10);

      setState(() {
        _totalPeserta = totalPeserta;
        _totalPending = totalPending;
        _totalDinilai = totalDinilai;
        _pesertaList = List<Map<String, dynamic>>.from(pesertaData.map((item) {
          return {
            'id': item['id'],
            'nama': item['peserta']?['users']?['name'] ?? '-',
            'email': item['peserta']?['users']?['email'] ?? '-',
            'nik': item['peserta']?['nik'] ?? '-',
            'skema': item['jadwal']?['skema']?['name'] ?? '-',
            'tanggal': item['jadwal']?['tanggal'] ?? '-',
            'status': item['nilai']?['status'] ?? 'pending',
          };
        }));
      });

      // Aktivitas terbaru
      final activities = await _supabase
          .from('nilai')
          .select('''
              status,
              created_at,
              pendaftaran!inner (
                  peserta!inner (
                      users!inner (
                          name
                      )
                  ),
                  jadwal!inner (
                      skema!inner (
                          name
                      )
                  )
              )
          ''')
          .eq('assessor_id', user.id)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _recentActivities = List<Map<String, dynamic>>.from(activities.map((item) {
          return {
            'nama': item['pendaftaran']?['peserta']?['users']?['name'] ?? '-',
            'skema': item['pendaftaran']?['jadwal']?['skema']?['name'] ?? '-',
            'status': item['status'] ?? 'pending',
            'created_at': item['created_at'] ?? '',
          };
        }));
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
  // LOAD NAMA PAKAR
  // ============================================================
  Future<void> _loadPakarName() async {
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
            _pakarName = userData['name'] ?? 'Pakar';
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
                colors: [const Color.fromARGB(255, 2, 95, 138), const Color.fromARGB(255, 155, 218, 243)],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: _isSidebarExpanded ? 20 : 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _pakarName.isNotEmpty ? _pakarName[0].toUpperCase() : 'P',
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
                          _pakarName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Pakar',
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
    final iconColor = isActive ? const Color.fromARGB(255, 89, 179, 182) : (color ?? Colors.grey[600]);
    final textColor = isActive ? const Color.fromARGB(255, 89, 163, 182) : (color ?? Colors.grey[700]);
    final bgColor = isActive ? const Color.fromARGB(255, 89, 168, 182).withValues(alpha: 0.08) : Colors.transparent;

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
                      color: const Color.fromARGB(255, 89, 168, 182),
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
                  colors: [const Color(0xFF9B59B6), const Color(0xFF8E44AD)],
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
                      _pakarName.isNotEmpty ? _pakarName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pakarName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Pakar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
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
    final iconColor = isActive ? const Color(0xFF9B59B6) : (color ?? Colors.grey[600]);
    final textColor = isActive ? const Color(0xFF9B59B6) : (color ?? Colors.grey[700]);
    final bgColor = isActive ? const Color(0xFF9B59B6).withOpacity(0.08) : Colors.transparent;

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
    _pages[0] = DashboardPakarContent(
      totalJadwal: _totalJadwal,
      totalPeserta: _totalPeserta,
      totalDinilai: _totalDinilai,
      totalPending: _totalPending,
      jadwalList: _jadwalList,
      pesertaList: _pesertaList,
      recentActivities: _recentActivities,
      pakarName: _pakarName,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F4FC),

      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                'Dashboard Pakar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color.fromARGB(255, 4, 209, 236)),
                  onPressed: _loadDashboardData,
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  onPressed: _logout,
                ),
              ],
            ),

      drawer: isDesktop ? null : _buildDrawer(),

      body: _isLoading && _selectedIndex == 0
          ? const Center(
              child: Column(
                //mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF9B59B6)),
                  SizedBox(height: 12),
                  Text('Memuat data...'),
                ],
              ),
            )
          : Row(
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: _selectedIndex == 0
                      ? _pages[0]
                      : Container(
                          padding: const EdgeInsets.all(0),
                          color: const Color(0xFFF8F4FC),
                          child: _pages[_selectedIndex],
                        ),
                ),
              ],
            ),
    );
  }
}

// ========DASHBOARD PAKAR CONTENT - WIDGET TERPISAH=======//
class DashboardPakarContent extends StatelessWidget {
  final int totalJadwal;
  final int totalPeserta;
  final int totalDinilai;
  final int totalPending;
  final List<Map<String, dynamic>> jadwalList;
  final List<Map<String, dynamic>> pesertaList;
  final List<Map<String, dynamic>> recentActivities;
  final String pakarName;

  final Color _pastelPurple = const Color(0xFFE8D5F5);
  final Color _pastelBlue = const Color(0xFFD5E8F5);
  final Color _pastelGreen = const Color(0xFFD5F5E8);
  final Color _pastelOrange = const Color(0xFFF5E8D5);

  const DashboardPakarContent({
    super.key,
    required this.totalJadwal,
    required this.totalPeserta,
    required this.totalDinilai,
    required this.totalPending,
    required this.jadwalList,
    required this.pesertaList,
    required this.recentActivities,
    required this.pakarName,
  });

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
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lulus':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'dinilai':
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
      case 'dinilai':
        return '📋 Dinilai';
      case 'tidak_lulus':
        return '❌ Tidak Lulus';
      default:
        return status;
    }
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPesertaTile(Map<String, dynamic> peserta) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: _pastelOrange,
        radius: 16,
        child: Text(
          peserta['nama'].isNotEmpty ? peserta['nama'][0].toUpperCase() : 'P',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE67E22),
          ),
        ),
      ),
      title: Text(
        peserta['nama'] ?? '-',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        peserta['skema'] ?? '-',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getStatusColor(peserta['status']).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _getStatusText(peserta['status']),
          style: TextStyle(
            fontSize: 9,
            color: _getStatusColor(peserta['status']),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      dense: true,
      onTap: () {},
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(activity['status']).withOpacity(0.15),
        radius: 12,
        child: Icon(
          activity['status'] == 'lulus' ? Icons.check_circle : Icons.pending,
          color: _getStatusColor(activity['status']),
          size: 12,
        ),
      ),
      title: Text(
        activity['nama'] ?? '-',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${activity['skema']} • ${_formatDateTimeAgo(activity['created_at'])}',
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
      dense: true,
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9B59B6)),
              ),
            ),
        ],
      ),
    );
  }

// ============================================================
// BUILD JADWAL ITEM
// ============================================================
Widget _buildJadwalItem(Map<String, dynamic> jadwal) {
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
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDate(jadwal['tanggal']).split('/')[0],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                _formatDate(jadwal['tanggal']).split('/')[1],
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jadwal['skema']?['name'] ?? '-',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(jadwal['waktu_mulai'])} - ${_formatTime(jadwal['waktu_selesai'])}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: jadwal['status'] == 'open'
                ? Colors.green.withOpacity(0.12)
                : Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            jadwal['status'] == 'open' ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: jadwal['status'] == 'open' ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // BUILD PESERTA ITEM
  // ============================================================
  Widget _buildPesertaItem(Map<String, dynamic> peserta) {
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
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orange.shade50,
            child: Text(
              peserta['nama'].isNotEmpty ? peserta['nama'][0].toUpperCase() : 'P',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peserta['nama'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  peserta['skema'] ?? '-',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(peserta['status']),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD ACTIVITY ITEM
  // ============================================================

  // ============================================================
  // BUILD EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[400],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    'Selamat datang, $pakarName! 👋',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    'Kelola penilaian ujian sertifikasi BNSP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: 400,
                    color: const Color.fromARGB(255, 4, 189, 235),
                  ),

                const SizedBox(height: 16),

                // ============================================
                // STATS GRID
                // ============================================
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4.0,
                  children: [
                    _buildStatsCard(
                      title: 'Total Jadwal',
                      value: totalJadwal.toString(),
                      icon: Icons.schedule,
                      bgColor: _pastelPurple,
                      iconColor: const Color(0xFF7B2FBE),
                    ),
                    _buildStatsCard(
                      title: 'Total Peserta',
                      value: totalPeserta.toString(),
                      icon: Icons.people,
                      bgColor: _pastelBlue,
                      iconColor: const Color(0xFF2E86DE),
                    ),
                    _buildStatsCard(
                      title: 'Sudah Dinilai',
                      value: totalDinilai.toString(),
                      icon: Icons.check_circle,
                      bgColor: _pastelGreen,
                      iconColor: const Color(0xFF27AE60),
                    ),
                    _buildStatsCard(
                      title: 'Pending',
                      value: totalPending.toString(),
                      icon: Icons.pending,
                      bgColor: _pastelOrange,
                      iconColor: const Color(0xFFE67E22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),



                // ============2 kolom=========================//
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // KOLOM KIRI - JADWAL UJIAN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('📅 Jadwal Ujian', actionText: 'Lihat Semua'),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: jadwalList.isNotEmpty
                                  ? Column(
                                      children: jadwalList
                                          .take(4)
                                          .map((jadwal) => _buildJadwalItem(jadwal))
                                          .toList(),
                                    )
                                  : _buildEmptyState('Belum ada jadwal ujian'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // KOLOM KANAN - PERLU DINILAI
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('👥 Perlu Dinilai', actionText: 'Lihat Semua'),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: pesertaList.isNotEmpty
                                  ? Column(
                                      children: pesertaList
                                          .take(4)
                                          .map((peserta) => _buildPesertaItem(peserta))
                                          .toList(),
                                    )
                                  : _buildEmptyState('✅ Semua peserta sudah dinilai'),
                            ),
                          ],
                        ),
                      ),
                    ],
                ),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: pesertaList.isNotEmpty
                      ? Column(
                          children: pesertaList
                              .take(2)
                              .map((peserta) => _buildPesertaTile(peserta))
                              .toList(),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              '✅ Semua peserta sudah dinilai',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // ============================================
                // AKTIVITAS TERBARU
                // ============================================
                _buildSectionHeader('📋 Aktivitas Terbaru'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: recentActivities.isNotEmpty
                      ? Column(
                          children: recentActivities
                              .take(2)
                              .map((activity) => _buildActivityTile(activity))
                              .toList(),
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Belum ada aktivitas penilaian',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
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

