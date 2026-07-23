import 'package:flutter/material.dart';
import '../../services/peserta_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class KelolaPeserta extends StatefulWidget {
  const KelolaPeserta({super.key});

  @override
  State<KelolaPeserta> createState() => _KelolaPesertaState();
}

class _KelolaPesertaState extends State<KelolaPeserta> {
  final _pesertaService = PesertaService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _pesertaList = [];
  List<Map<String, dynamic>> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _pesertaService.getAllPeserta();
      setState(() {
        _pesertaList = data;
        _filteredList = data;
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
  // SEARCH
  // ============================================================
  void _searchPeserta(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _filteredList = _pesertaList;
      } else {
        _filteredList = _pesertaList.where((item) {
          final name = item['users']?['name']?.toLowerCase() ?? '';
          final email = item['users']?['email']?.toLowerCase() ?? '';
          final nik = item['nik']?.toLowerCase() ?? '';
          final search = keyword.toLowerCase();
          return name.contains(search) ||
              email.contains(search) ||
              nik.contains(search);
        }).toList();
      }
    });
  }

  // ============================================================
  // FILTER BY STATUS
  // ============================================================
  void _filterByStatus(String? status) {
    setState(() {
      if (status == null || status == 'semua') {
        _filteredList = _pesertaList;
      } else {
        _filteredList = _pesertaList.where((item) {
          return item['status'] == status;
        }).toList();
      }
    });
  }

  // ============================================================
  // DELETE PESERTA
  // ============================================================
  Future<void> _deletePeserta(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Peserta'),
        content: Text('Apakah Anda yakin ingin menghapus peserta "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _pesertaService.deletePeserta(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peserta berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal hapus peserta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // BUILD STATUS BADGE
  // ============================================================
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = '⏳ Pending';
        break;
      case 'verifikasi':
        color = Colors.blue;
        label = '📋 Verifikasi';
        break;
      case 'lulus':
        color = Colors.green;
        label = '✅ Lulus';
        break;
      case 'tidak_lulus':
        color = Colors.red;
        label = '❌ Tidak Lulus';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD DOKUMEN ICON
  // ============================================================
  Widget _buildDokumenIcon(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.file_present, color: Colors.grey, size: 16);
    }
    return const Icon(Icons.check_circle, color: Colors.green, size: 16);
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Peserta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // SEARCH & FILTER
          // ============================================================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari peserta...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _searchPeserta,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: _filterByStatus,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'semua',
                      child: Text('Semua Status'),
                    ),
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('⏳ Pending'),
                    ),
                    const PopupMenuItem(
                      value: 'verifikasi',
                      child: Text('📋 Verifikasi'),
                    ),
                    const PopupMenuItem(
                      value: 'lulus',
                      child: Text('✅ Lulus'),
                    ),
                    const PopupMenuItem(
                      value: 'tidak_lulus',
                      child: Text('❌ Tidak Lulus'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================================
          // STATS
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildStatsChip('Total', _pesertaList.length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('Pending', 
                    _pesertaList.where((p) => p['status'] == 'pending').length, 
                    Colors.orange),
                const SizedBox(width: 8),
                _buildStatsChip('Verifikasi', 
                    _pesertaList.where((p) => p['status'] == 'verifikasi').length, 
                    Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('Lulus', 
                    _pesertaList.where((p) => p['status'] == 'lulus').length, 
                    Colors.green),
              ],
            ),
          ),

          // ============================================================
          // LIST PESERTA
          // ============================================================
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredList.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: 'Tidak ada peserta',
                        subtitle: 'Belum ada peserta yang terdaftar',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final user = item['users'] as Map? ?? {};
                          final name = user['name'] ?? 'Tidak Diketahui';
                          final email = user['email'] ?? '-';
                          final nik = item['nik'] ?? '-';
                          final status = item['status'] ?? 'pending';
                          final dokumenKtp = item['dokumen_ktp'];
                          final dokumenIjazah = item['dokumen_ijazah'];
                          final dokumenSkor = item['dokumen_skor'];
                          final totalDokumen = [
                            dokumenKtp, dokumenIjazah, dokumenSkor
                          ].where((d) => d != null && d.isNotEmpty).length;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue.withOpacity(0.1),
                                        radius: 20,
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              'NIK: $nik',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // DOKUMEN
                                      Row(
                                        children: [
                                          _buildDokumenIcon(dokumenKtp),
                                          const SizedBox(width: 2),
                                          const Text('KTP', style: TextStyle(fontSize: 10)),
                                          const SizedBox(width: 8),
                                          _buildDokumenIcon(dokumenIjazah),
                                          const SizedBox(width: 2),
                                          const Text('Ijazah', style: TextStyle(fontSize: 10)),
                                          const SizedBox(width: 8),
                                          _buildDokumenIcon(dokumenSkor),
                                          const SizedBox(width: 2),
                                          const Text('Skor', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$totalDokumen/3 dokumen',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // VERIFIKASI
                                      if (status == 'pending' && totalDokumen == 3)
                                        TextButton(
                                          onPressed: () {
                                            _showVerifikasiDialog(item['id'], name);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            backgroundColor: Colors.blue.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Verifikasi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      // EDIT
                                      TextButton(
                                        onPressed: () {
                                          _showEditDialog(item);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: Colors.grey.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // HAPUS
                                      TextButton(
                                        onPressed: () {
                                          _deletePeserta(item['id'], name);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          backgroundColor: Colors.red.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // STATS CHIP
  // ============================================================
  Widget _buildStatsChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // SHOW ADD DIALOG
  // ============================================================
  void _showAddDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final nikController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Peserta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                ),
                maxLength: 16,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. HP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implementasi tambah peserta
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHOW EDIT DIALOG
  // ============================================================
  void _showEditDialog(Map<String, dynamic> peserta) {
    final user = peserta['users'] as Map? ?? {};
    final nameController = TextEditingController(text: user['name'] ?? '');
    final nikController = TextEditingController(text: peserta['nik'] ?? '');
    final phoneController = TextEditingController(text: peserta['phone'] ?? '');
    final addressController = TextEditingController(text: peserta['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Peserta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                ),
                maxLength: 16,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. HP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implementasi update peserta
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHOW VERIFIKASI DIALOG
  // ============================================================
  void _showVerifikasiDialog(String pesertaId, String name) {
    // ignore: unused_local_variable
    String? catatan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Dokumen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Verifikasi dokumen peserta: $name'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => catatan = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tolak'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implementasi verifikasi
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }
}