import 'package:appsertifikat/pages/admin/kelola_jadwal.dart';
import 'package:appsertifikat/pages/admin/kelola_peserta.dart';
import 'package:appsertifikat/pages/admin/kelola_skema.dart';
import 'package:appsertifikat/pages/admin/penerbitan_sertifikat.dart';
import 'package:appsertifikat/pages/admin/verifikasi_dokumen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';
import 'login_page.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  bool _isSidebarExpanded = true;
  int _selectedIndex = 0;
  String _adminName = 'Admin';

  // Data Dashboard
  int _totalPeserta = 0;
  int _totalJadwal = 0;
  int _totalSkema = 0;
  int _sertifikatTerbit = 0;
  int _pendingVerifikasi = 0;
  List<Map<String, dynamic>> _recentActivities = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();


  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'title': 'Dashboard', 'index': 0},
    {'icon': Icons.people, 'title': 'Peserta', 'index': 1},
    {'icon': Icons.category, 'title': 'Skema', 'index': 2},
    {'icon': Icons.schedule, 'title': 'Jadwal', 'index': 3},
    {'icon': Icons.assignment, 'title': 'Dokumen', 'index': 4},
    {'icon': Icons.verified, 'title': 'Sertifikat', 'index': 5},
  ];

  // ============================================================
  // LIST HALAMAN
  // ============================================================
  final List<Widget> _pages = [
    DashboardContent(
      totalPeserta: 0,
      totalJadwal: 0,
      totalSkema: 0,
      sertifikatTerbit: 0,
      pendingVerifikasi: 0,
      recentActivities: [],
      adminName: 'Admin',
    ),
    const KelolaPeserta(),
    const KelolaSkema(),
    const KelolaJadwal(),
    const VerifikasiDokumen(),
    const PenerbitanSertifikat(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAdminName();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final totalPeserta = await _getCount('peserta');
      final totalJadwal = await _getCount('jadwal');
      final totalSkema = await _getCount('skema');
      final totalSertifikat = await _getCount('sertifikat');
      final totalPending = await _getCount('peserta', column: 'status', value: 'pending');

      final activities = await _supabase
          .from('peserta')
          .select('''
            status,
            created_at,
            users!peserta_user_id_fkey (
              name,
              email
            )
          ''')
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _totalPeserta = totalPeserta;
        _totalJadwal = totalJadwal;
        _totalSkema = totalSkema;
        _sertifikatTerbit = totalSertifikat;
        _pendingVerifikasi = totalPending;
        _recentActivities = List<Map<String, dynamic>>.from(activities);
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

  Future<int> _getCount(String table, {String? column, String? value}) async {
    try {
      if (column != null && value != null) {
        final response = await _supabase.from(table).select().eq(column, value).count();
        return response.count;
      } else {
        final response = await _supabase.from(table).select().count();
        return response.count;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadAdminName() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userData = await _supabase.from('users').select('name').eq('id', user.id).maybeSingle();
        if (userData != null && mounted) {
          setState(() => _adminName = userData['name'] ?? 'Admin');
        }
      }
    } catch (e) {}
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal[700]!, Colors.teal[800]!]),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: _isSidebarExpanded ? 20 : 16,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
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
                        Text(_adminName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Administrator', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(_isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right, size: 16, color: Colors.grey[600]),
                onPressed: _toggleSidebar,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          const Divider(height: 1),
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
                _buildSidebarTile(icon: Icons.logout, title: 'Logout', color: Colors.red, onTap: _logout),
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
    final iconColor = isActive ? Colors.teal : (color ?? Colors.grey[600]);
    final textColor = isActive ? Colors.teal : (color ?? Colors.grey[700]);
    final bgColor = isActive ? Colors.teal.withOpacity(0.08) : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive) Container(width: 3, height: 16, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(2))),
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
        borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.teal[700]!, Colors.teal[800]!]),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(_adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(_adminName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Administrator', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
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
            _buildDrawerTile(icon: Icons.logout, title: 'Logout', color: Colors.red, onTap: _logout),
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
    final iconColor = isActive ? Colors.teal : (color ?? Colors.grey[600]);
    final textColor = isActive ? Colors.teal : (color ?? Colors.grey[700]);
    final bgColor = isActive ? Colors.teal.withOpacity(0.08) : Colors.transparent;

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      visualDensity: VisualDensity.compact,
      tileColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Update pages dengan data terbaru
    _pages[0] = DashboardContent(
      totalPeserta: _totalPeserta,
      totalJadwal: _totalJadwal,
      totalSkema: _totalSkema,
      sertifikatTerbit: _sertifikatTerbit,
      pendingVerifikasi: _pendingVerifikasi,
      recentActivities: _recentActivities,
      adminName: _adminName,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Dashboard Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
              actions: [
                IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _loadDashboardData),
                IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: _logout),
              ],
            ),

      drawer: isDesktop ? null : _buildDrawer(),

      body: _isLoading && _selectedIndex == 0
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: _selectedIndex == 0
                      ? _pages[0]
                      : Container(
                          color: const Color.fromARGB(255, 237, 245, 245),
                          child: _pages[_selectedIndex],
                        ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// DASHBOARD CONTENT - WIDGET TERPISAH
// ============================================================
class DashboardContent extends StatelessWidget {
  final int totalPeserta;
  final int totalJadwal;
  final int totalSkema;
  final int sertifikatTerbit;
  final int pendingVerifikasi;
  final List<Map<String, dynamic>> recentActivities;
  final String adminName;

  final Color _pastelBlue = const Color(0xFFE3F2FD);
  final Color _pastelGreen = const Color(0xFFE8F5E9);
  final Color _pastelOrange = const Color(0xFFFFF3E0);
  final Color _pastelPurple = const Color(0xFFF3E5F5);

  const DashboardContent({
    super.key,
    required this.totalPeserta,
    required this.totalJadwal,
    required this.totalSkema,
    required this.sertifikatTerbit,
    required this.pendingVerifikasi,
    required this.recentActivities,
    required this.adminName,
  });

  String _formatDate(String dateString) {
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


  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            if (subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Text(subtitle, style: TextStyle(fontSize: 9, color: iconColor, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (recentActivities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Belum ada aktivitas terbaru', style: TextStyle(fontSize: 13, color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentActivities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = recentActivities[index];
        final name = activity['name'] ?? 'Peserta';
        final status = activity['status'] ?? 'pending';
        final createdAt = activity['created_at'] ?? '';

        String statusText;
        Color statusColor;
        IconData statusIcon;

        switch (status) {
          case 'lulus':
            statusText = 'Lulus';
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'pending':
            statusText = 'Pending';
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'verifikasi':
            statusText = 'Verifikasi';
            statusColor = Colors.blue;
            statusIcon = Icons.verified;
            break;
          case 'tidak_lulus':
            statusText = 'Tidak Lulus';
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusText = status;
            statusColor = Colors.grey;
            statusIcon = Icons.info;
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.15),
            radius: 14,
            child: Icon(statusIcon, color: statusColor, size: 14),
          ),
          title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          subtitle: Text(
            'Status: $statusText • ${_formatDate(createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(statusText, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w600)),
          ),
          dense: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WELCOME
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[50]!, Colors.teal[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat datang, $adminName! 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('Kelola proses sertifikasi BNSP dengan mudah.', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // STATS
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4.0,
            children: [
              _buildStatsCard(
                title: 'Total Peserta',
                value: totalPeserta.toString(),
                icon: Icons.people,
                bgColor: _pastelBlue,
                iconColor: Colors.blue.shade700,
                subtitle: '$pendingVerifikasi pending',
              ),
              _buildStatsCard(
                title: 'Total Jadwal',
                value: totalJadwal.toString(),
                icon: Icons.schedule,
                bgColor: _pastelGreen,
                iconColor: Colors.green.shade700,
              ),
              _buildStatsCard(
                title: 'Total Skema',
                value: totalSkema.toString(),
                icon: Icons.category,
                bgColor: _pastelOrange,
                iconColor: Colors.orange.shade700,
              ),
              _buildStatsCard(
                title: 'Sertifikat Terbit',
                value: sertifikatTerbit.toString(),
                icon: Icons.verified,
                bgColor: _pastelPurple,
                iconColor: Colors.purple.shade700,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // QUICK ACTION
          Text('⚡ Aksi Cepat', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildQuickAction(icon: Icons.person_add, label: 'Tambah Peserta', bgColor: _pastelBlue, iconColor: Colors.blue.shade700),
              _buildQuickAction(icon: Icons.add_circle, label: 'Tambah Skema', bgColor: _pastelOrange, iconColor: Colors.orange.shade700),
              _buildQuickAction(icon: Icons.event, label: 'Tambah Jadwal', bgColor: _pastelGreen, iconColor: Colors.green.shade700),
              _buildQuickAction(icon: Icons.assignment_turned_in, label: 'Verifikasi', bgColor: _pastelPurple, iconColor: Colors.purple.shade700),
            ],
          ),
          const SizedBox(height: 24),

          // ACTIVITY
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📋 Aktivitas Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text('Lihat Semua →', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildActivityList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}