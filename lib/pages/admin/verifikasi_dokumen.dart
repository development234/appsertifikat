import 'package:flutter/material.dart';
import '../../services/dokumen_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class VerifikasiDokumen extends StatefulWidget {
  const VerifikasiDokumen({super.key});

  @override
  State<VerifikasiDokumen> createState() => _VerifikasiDokumenState();
}

class _VerifikasiDokumenState extends State<VerifikasiDokumen> {
  final _dokumenService = DokumenService();

  bool _isLoading = true;
  String _searchKeyword = '';
  String _filterStatus = 'semua';
  List<Map<String, dynamic>> _pendingList = [];
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
      final data = await _dokumenService.getDokumenPending();
      setState(() {
        _pendingList = data;
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
  // SEARCH & FILTER
  // ============================================================
  void _searchDokumen(String keyword) {
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
    _filteredList = _pendingList.where((item) {
      final user = item['users'] as Map? ?? {};
      final name = user['name']?.toLowerCase() ?? '';
      final nik = item['nik']?.toLowerCase() ?? '';
      final search = _searchKeyword.toLowerCase();

      final matchSearch = name.contains(search) || nik.contains(search);

      // Filter status
      bool matchStatus = true;
      if (_filterStatus == 'lengkap') {
        matchStatus = _isDokumenLengkap(item);
      } else if (_filterStatus == 'belum_lengkap') {
        matchStatus = !_isDokumenLengkap(item);
      }

      return matchSearch && matchStatus;
    }).toList();
  }

  // ============================================================
  // CEK DOKUMEN LENGKAP
  // ============================================================
  bool _isDokumenLengkap(Map<String, dynamic> item) {
    final ktp = item['dokumen_ktp'] != null && item['dokumen_ktp'].isNotEmpty;
    final ijazah = item['dokumen_ijazah'] != null && item['dokumen_ijazah'].isNotEmpty;
    final skor = item['dokumen_skor'] != null && item['dokumen_skor'].isNotEmpty;
    return ktp && ijazah && skor;
  }

  int _getDokumenCount(Map<String, dynamic> item) {
    int count = 0;
    if (item['dokumen_ktp'] != null && item['dokumen_ktp'].isNotEmpty) count++;
    if (item['dokumen_ijazah'] != null && item['dokumen_ijazah'].isNotEmpty) count++;
    if (item['dokumen_skor'] != null && item['dokumen_skor'].isNotEmpty) count++;
    return count;
  }

  String _getDokumenIcon(Map<String, dynamic> item, String jenis) {
    String key;
    switch (jenis) {
      case 'ktp':
        key = 'dokumen_ktp';
        break;
      case 'ijazah':
        key = 'dokumen_ijazah';
        break;
      case 'skor':
        key = 'dokumen_skor';
        break;
      default:
        return '';
    }
    final url = item[key];
    if (url != null && url.isNotEmpty) {
      return '✅';
    }
    return '❌';
  }

  // ============================================================
  // VERIFIKASI DOKUMEN
  // ============================================================
  Future<void> _verifikasiDokumen(String pesertaId, bool status, {String? catatan}) async {
    final result = await _dokumenService.verifikasiDokumen(
      pesertaId: pesertaId,
      status: status,
      catatan: catatan,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Berhasil'),
          backgroundColor: status ? Colors.green : Colors.orange,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal verifikasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SHOW VERIFIKASI DIALOG
  // ============================================================
  void _showVerifikasiDialog(Map<String, dynamic> item) {
    final user = item['users'] as Map? ?? {};
    final name = user['name'] ?? 'Tidak Diketahui';
    final nik = item['nik'] ?? '-';
    final ktp = item['dokumen_ktp'] ?? '';
    final ijazah = item['dokumen_ijazah'] ?? '';
    final skor = item['dokumen_skor'] ?? '';
    final isLengkap = _isDokumenLengkap(item);

    String? catatan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Dokumen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informasi Peserta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama: $name',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('NIK: $nik'),
                    Text(
                      'Status Dokumen: ${isLengkap ? "✅ Lengkap" : "⚠️ Belum Lengkap"}',
                      style: TextStyle(
                        color: isLengkap ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Daftar Dokumen
              const Text(
                'Dokumen yang Diupload:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildDokumenPreview('KTP', ktp),
              const SizedBox(height: 4),
              _buildDokumenPreview('Ijazah', ijazah),
              const SizedBox(height: 4),
              _buildDokumenPreview('Skor', skor),
              const SizedBox(height: 12),

              // Catatan
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Masukkan catatan verifikasi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) => catatan = value,
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
              Navigator.pop(context);
              await _verifikasiDokumen(
                item['id'],
                false,
                catatan: catatan ?? 'Dokumen tidak memenuhi syarat',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _verifikasiDokumen(
                item['id'],
                true,
                catatan: catatan ?? 'Dokumen lengkap dan valid',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD DOKUMEN PREVIEW
  // ============================================================
  Widget _buildDokumenPreview(String label, String url) {
    final hasDokumen = url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasDokumen ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDokumen ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            hasDokumen ? '✅' : '❌',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${hasDokumen ? "Telah diupload" : "Belum diupload"}',
              style: TextStyle(
                color: hasDokumen ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
          if (hasDokumen)
            IconButton(
              icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
              onPressed: () {
                _showDokumenPreview(url);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SHOW DOKUMEN PREVIEW
  // ============================================================
  void _showDokumenPreview(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview Dokumen'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  url.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  url.split('/').last,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Download dokument
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tutup'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
    final lengkapCount = _pendingList.where(_isDokumenLengkap).length;
    final belumLengkapCount = _pendingList.length - lengkapCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Dokumen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.purple),
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
                    onChanged: _searchDokumen,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: _filterByStatus,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'semua',
                      child: Text('Semua'),
                    ),
                    const PopupMenuItem(
                      value: 'lengkap',
                      child: Text('✅ Lengkap'),
                    ),
                    const PopupMenuItem(
                      value: 'belum_lengkap',
                      child: Text('❌ Belum Lengkap'),
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
                _buildStatsChip('Total', _pendingList.length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('✅ Lengkap', lengkapCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatsChip('❌ Belum', belumLengkapCount, Colors.orange),
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
                        title: 'Tidak ada dokumen pending',
                        subtitle: 'Semua dokumen sudah diverifikasi',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final user = item['users'] as Map? ?? {};
                          final name = user['name'] ?? 'Tidak Diketahui';
                          final nik = item['nik'] ?? '-';
                          final status = item['status'] ?? 'pending';
                          final isLengkap = _isDokumenLengkap(item);
                          final totalDokumen = _getDokumenCount(item);

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
                                      CircleAvatar(
                                        backgroundColor:
                                            isLengkap
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.orange.withOpacity(0.1),
                                        radius: 20,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isLengkap
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
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
                                  const SizedBox(height: 10),

                                  // DOKUMEN STATUS
                                  Row(
                                    children: [
                                      _buildDokumenChip('KTP', _getDokumenIcon(item, 'ktp')),
                                      const SizedBox(width: 8),
                                      _buildDokumenChip('Ijazah', _getDokumenIcon(item, 'ijazah')),
                                      const SizedBox(width: 8),
                                      _buildDokumenChip('Skor', _getDokumenIcon(item, 'skor')),
                                      const Spacer(),
                                      Text(
                                        '$totalDokumen/3 dokumen',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // ACTION BUTTON
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isLengkap && status == 'pending')
                                        ElevatedButton(
                                          onPressed: () {
                                            _showVerifikasiDialog(item);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 8,
                                            ),
                                            backgroundColor: Colors.purple,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Verifikasi',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      if (!isLengkap)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '⚠️ Dokumen belum lengkap',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange[700],
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
    );
  }

  // ============================================================
  // BUILD DOKUMEN CHIP
  // ============================================================
  Widget _buildDokumenChip(String label, String status) {
    final isUploaded = status == '✅';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isUploaded ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}