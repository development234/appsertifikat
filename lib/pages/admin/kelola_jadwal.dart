import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/jadwal_service.dart';
import '../../services/skema_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class KelolaJadwal extends StatefulWidget {
  const KelolaJadwal({super.key});

  @override
  State<KelolaJadwal> createState() => _KelolaJadwalState();
}

class _KelolaJadwalState extends State<KelolaJadwal> {
  final _jadwalService = JadwalService();
  final _skemaService = SkemaService();

  bool _isLoading = true;
  String _searchKeyword = '';
  String _filterStatus = 'semua';
  List<Map<String, dynamic>> _jadwalList = [];
  List<Map<String, dynamic>> _filteredList = [];
  List<Map<String, dynamic>> _skemaList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========== LOAD DATA====================//
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final jadwal = await _jadwalService.getAllJadwal();
      final skema = await _skemaService.getAllSkema();

      setState(() {
        _jadwalList = jadwal;
        _filteredList = jadwal;
        _skemaList = skema;
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

  // =============SEARCH & FILTER==============//
  void _searchJadwal(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _applyFilter();
    });
  }

  void _filterByStatus(String? status) {
    setState(() {
      _filterStatus = status ?? 'semua';
      _applyFilter();
    });
  }

  void _applyFilter() {
    _filteredList = _jadwalList.where((item) {
      final skema = item['skema'] as Map? ?? {};
      final name = skema['name']?.toLowerCase() ?? '';
      final code = skema['code']?.toLowerCase() ?? '';
      final status = item['status']?.toLowerCase() ?? '';
      final search = _searchKeyword.toLowerCase();

      final matchSearch = name.contains(search) || code.contains(search);
      final matchStatus = _filterStatus == 'semua' || status == _filterStatus;

      return matchSearch && matchStatus;
    }).toList();
  }

  // =========== FORMAT DATE============//
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '-';
    try {
      final time = DateTime.parse('2024-01-01T$timeString');
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return timeString;
    }
  }


// =========SHOW ADD DIALOG - PERBAIKAN========//
void _showAddDialog() {
  String? selectedSkemaId;
  DateTime.now().add(const Duration(days: 7));

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tambah Jadwal Ujian'),
      content: SingleChildScrollView(
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SKEMA
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Pilih Skema *',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedSkemaId,
                  items: _skemaList.map((skema) {
                    return DropdownMenuItem<String>(
                      value: skema['id'] as String? ?? '',  // ← PERBAIKAN
                      child: Text('${skema['code']} - ${skema['name']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedSkemaId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Skema wajib dipilih';
                    }
                    return null;
                  },
                ),
                // ... sisanya sama
              ],
            );
          },
        ),
      ),
    ),
  );
}

  // ===========SHOW EDIT DIALOG========================//
  void _showEditDialog(Map<String, dynamic> jadwal) {

    DateTime.parse(jadwal['tanggal'] ?? DateTime.now().toIso8601String());
    (jadwal['waktu_mulai'] ?? '09:00').split(':');
    (jadwal['waktu_selesai'] ?? '12:00').split(':');

  }

  // ============DELETE JADWAL=============================//
  Future<void> _deleteJadwal(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal "$name"?'),
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
      final result = await _jadwalService.deleteJadwal(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal hapus jadwal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =============TOGGLE STATUS===============================//
  Future<void> _toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'open' ? 'closed' : 'open';
    final result = await _jadwalService.updateStatus(
      id: id,
      status: newStatus,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status berhasil diubah menjadi ${newStatus == 'open' ? '🟢 Open' : '🔴 Closed'}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal ubah status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===========BUILD STATUS BADGE===========================//
  Widget _buildStatusBadge(String status) {
    if (status == 'open') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.green, size: 8),
            SizedBox(width: 4),
            Text(
              'Open',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.red, size: 8),
            SizedBox(width: 4),
            Text(
              'Closed',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }
  }

  // =========BUILD STATS CHIP==============================//
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

  // =========BUILD============================//
  @override
  Widget build(BuildContext context) {
    final openCount = _jadwalList.where((j) => j['status'] == 'open').length;
    final closedCount = _jadwalList.where((j) => j['status'] == 'closed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Kelola Jadwal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH & FILTER
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari jadwal...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _searchJadwal,
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
                      value: 'open',
                      child: Text('🟢 Open'),
                    ),
                    const PopupMenuItem(
                      value: 'closed',
                      child: Text('🔴 Closed'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // STATS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildStatsChip('Total', _jadwalList.length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('🟢 Open', openCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatsChip('🔴 Closed', closedCount, Colors.red),
              ],
            ),
          ),

          // LIST JADWAL
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredList.isEmpty
                    ? EmptyState(
                        icon: Icons.event_busy,
                        title: 'Tidak ada jadwal',
                        subtitle: 'Belum ada jadwal ujian yang dibuat',
                        buttonText: 'Tambah Jadwal',
                        onButtonPressed: _showAddDialog,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final skema = item['skema'] as Map? ?? {};
                          final id = item['id'] ?? '';
                          final skemaName = skema['name'] ?? '-';
                          final skemaCode = skema['code'] ?? '-';
                          final tanggal = item['tanggal'] ?? '-';
                          final waktuMulai = item['waktu_mulai'] ?? '-';
                          final waktuSelesai = item['waktu_selesai'] ?? '-';
                          final kuota = item['kuota'] ?? 0;
                          final lokasi = item['lokasi'] ?? '-';
                          final status = item['status'] ?? 'closed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.event,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              skemaName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              skemaCode,
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(tanggal),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_formatTime(waktuMulai)} - ${_formatTime(waktuSelesai)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        lokasi,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.people, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Kuota: $kuota',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // TOGGLE STATUS
                                      TextButton(
                                        onPressed: () {
                                          _toggleStatus(id, status);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          backgroundColor: status == 'open'
                                              ? Colors.red.withOpacity(0.1)
                                              : Colors.green.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          status == 'open' ? 'Tutup' : 'Buka',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: status == 'open'
                                                ? Colors.red
                                                : Colors.green,
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          backgroundColor:
                                              Colors.grey.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                          _deleteJadwal(id, skemaName);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          backgroundColor:
                                              Colors.red.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
        onPressed: _showAddDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}