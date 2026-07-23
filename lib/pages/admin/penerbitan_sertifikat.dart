import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sertifikat_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class PenerbitanSertifikat extends StatefulWidget {
  const PenerbitanSertifikat({super.key});

  @override
  State<PenerbitanSertifikat> createState() => _PenerbitanSertifikatState();
}

class _PenerbitanSertifikatState extends State<PenerbitanSertifikat> {
  final _sertifikatService = SertifikatService();

  bool _isLoading = true;
  String _searchKeyword = '';
  String _filterStatus = 'semua';
  List<Map<String, dynamic>> _sertifikatList = [];
  List<Map<String, dynamic>> _filteredList = [];
  List<Map<String, dynamic>> _pesertaLulus = [];

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
      final sertifikat = await _sertifikatService.getAllSertifikat();
      final pesertaLulus = await _sertifikatService.getPesertaLulus();

      setState(() {
        _sertifikatList = sertifikat;
        _filteredList = sertifikat;
        _pesertaLulus = pesertaLulus;
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
  // SEARCH & FILTER
  // ============================================================
  void _searchSertifikat(String keyword) {
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
    _filteredList = _sertifikatList.where((item) {
      final nomor = item['nomor_sertifikat']?.toLowerCase() ?? '';
      final peserta = item['peserta'] as Map? ?? {};
      final user = peserta['users'] as Map? ?? {};
      final name = user['name']?.toLowerCase() ?? '';
      final search = _searchKeyword.toLowerCase();

      final matchSearch = nomor.contains(search) || name.contains(search);
      final matchStatus = _filterStatus == 'semua' || item['status'] == _filterStatus;

      return matchSearch && matchStatus;
    }).toList();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // ============================================================
  // TERBITKAN SERTIFIKAT
  // ============================================================

  // ============================================================
  // TERBITKAN MASAL
  // ============================================================
  Future<void> _terbitkanMassal() async {
    if (_pesertaLulus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada peserta yang layak menerima sertifikat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terbitkan Sertifikat Massal'),
        content: Text(
          'Apakah Anda yakin ingin menerbitkan ${_pesertaLulus.length} sertifikat sekaligus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Ya, Terbitkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      int success = 0;
      int failed = 0;

      for (var peserta in _pesertaLulus) {
        final result = await _sertifikatService.terbitkanSertifikat(
          pesertaId: peserta['id'],
        );
        if (result['success']) {
          success++;
        } else {
          failed++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $success sertifikat berhasil diterbitkan, $failed gagal'),
          backgroundColor: success > 0 ? Colors.green : Colors.red,
        ),
      );
      _loadData();
    }
  }

  // ============================================================
  // BATALKAN SERTIFIKAT
  // ============================================================
  Future<void> _batalkanSertifikat(String id, String nomor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Sertifikat'),
        content: Text(
          'Apakah Anda yakin ingin membatalkan sertifikat nomor "$nomor"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _sertifikatService.batalkanSertifikat(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sertifikat berhasil dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal batalkan sertifikat'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // SHOW DETAIL DIALOG
  // ============================================================
  void _showDetailDialog(Map<String, dynamic> sertifikat) {
    final peserta = sertifikat['peserta'] as Map? ?? {};
    final user = peserta['users'] as Map? ?? {};
    final skema = sertifikat['skema'] as Map? ?? {};
    final name = user['name'] ?? 'Tidak Diketahui';
    final nik = peserta['nik'] ?? '-';
    final skemaName = skema['name'] ?? '-';
    final nomor = sertifikat['nomor_sertifikat'] ?? '-';
    final tanggal = sertifikat['tanggal_terbit'] ?? '-';
    final status = sertifikat['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Sertifikat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nomor Sertifikat', nomor),
              const Divider(),
              _buildDetailRow('Nama Peserta', name),
              _buildDetailRow('NIK', nik),
              _buildDetailRow('Skema', skemaName),
              _buildDetailRow('Tanggal Terbit', _formatDate(tanggal)),
              _buildDetailRow(
                'Status',
                status == 'active' ? '✅ Aktif' : '❌ Dibatalkan',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Download PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download sertifikat PDF'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 16),
                SizedBox(width: 4),
                Text('Download PDF'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD STATUS BADGE
  // ============================================================
  Widget _buildStatusBadge(String status) {
    if (status == 'active') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 12),
            SizedBox(width: 4),
            Text(
              'Aktif',
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
            Icon(Icons.cancel, color: Colors.red, size: 12),
            SizedBox(width: 4),
            Text(
              'Dibatalkan',
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

  // ============================================================
  // BUILD STATS CHIP
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final activeCount = _sertifikatList.where((s) => s['status'] == 'active').length;
    final cancelledCount = _sertifikatList.where((s) => s['status'] == 'cancelled').length;
    final layakCount = _pesertaLulus.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Penerbitan Sertifikat',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.teal),
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
                      hintText: 'Cari sertifikat...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _searchSertifikat,
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
                      value: 'active',
                      child: Text('✅ Aktif'),
                    ),
                    const PopupMenuItem(
                      value: 'cancelled',
                      child: Text('❌ Dibatalkan'),
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
                _buildStatsChip('Total', _sertifikatList.length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('✅ Aktif', activeCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatsChip('❌ Dibatalkan', cancelledCount, Colors.red),
                const SizedBox(width: 8),
                _buildStatsChip('📋 Layak', layakCount, Colors.teal),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredList.isEmpty
                    ? EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Belum ada sertifikat',
                        subtitle: 'Belum ada sertifikat yang diterbitkan',
                        buttonText: 'Terbitkan Sertifikat',
                        onButtonPressed: _terbitkanMassal,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final peserta = item['peserta'] as Map? ?? {};
                          final user = peserta['users'] as Map? ?? {};
                          final skema = item['skema'] as Map? ?? {};
                          final name = user['name'] ?? 'Tidak Diketahui';
                          final nik = peserta['nik'] ?? '-';
                          final nomor = item['nomor_sertifikat'] ?? '-';
                          final tanggal = item['tanggal_terbit'] ?? '-';
                          final status = item['status'] ?? 'active';

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
                                          color: status == 'active'
                                              ? Colors.teal.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.verified,
                                          color: status == 'active'
                                              ? Colors.teal
                                              : Colors.red,
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
                                              name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'NIK: $nik',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
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
                                      const Icon(Icons.confirmation_number,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'No: $nomor',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(tanggal),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        skema['name'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // DETAIL
                                      TextButton(
                                        onPressed: () {
                                          _showDetailDialog(item);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          backgroundColor:
                                              Colors.blue.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Detail',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // DOWNLOAD
                                      TextButton(
                                        onPressed: () {
                                          // TODO: Download PDF
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Download sertifikat PDF'),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                          backgroundColor:
                                              Colors.green.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Download',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (status == 'active') ...[
                                        const SizedBox(width: 8),
                                        // BATALKAN
                                        TextButton(
                                          onPressed: () {
                                            _batalkanSertifikat(
                                              item['id'],
                                              nomor,
                                            );
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
                                            'Batalkan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pesertaLulus.isNotEmpty)
            FloatingActionButton(
              heroTag: 'massal',
              onPressed: _terbitkanMassal,
              backgroundColor: Colors.teal,
              mini: true,
              child: const Icon(Icons.verified, color: Colors.white),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'single',
            onPressed: () {
              // TODO: Show dialog untuk pilih peserta
            },
            backgroundColor: Colors.teal,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}