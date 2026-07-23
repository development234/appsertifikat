import 'package:flutter/material.dart';
import '../../services/skema_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class KelolaSkema extends StatefulWidget {
  const KelolaSkema({super.key});

  @override
  State<KelolaSkema> createState() => _KelolaSkemaState();
}

class _KelolaSkemaState extends State<KelolaSkema> {
  final _skemaService = SkemaService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _skemaList = [];
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
      final data = await _skemaService.getAllSkema();
      setState(() {
        _skemaList = data;
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
  void _searchSkema(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _filteredList = _skemaList;
      } else {
        _filteredList = _skemaList.where((item) {
          final name = item['name']?.toLowerCase() ?? '';
          final code = item['code']?.toLowerCase() ?? '';
          final search = keyword.toLowerCase();
          return name.contains(search) || code.contains(search);
        }).toList();
      }
    });
  }

  // ============================================================
  // SHOW ADD DIALOG
  // ============================================================
  void _showAddDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final durasiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Skema Sertifikasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Skema *',
                  hintText: 'Contoh: BNSP-001',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Skema *',
                  hintText: 'Contoh: Junior Network Administrator',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Deskripsi skema sertifikasi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durasiController,
                decoration: const InputDecoration(
                  labelText: 'Durasi Ujian (menit) *',
                  hintText: 'Contoh: 120',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final durasi = int.tryParse(durasiController.text.trim()) ?? 120;

              if (code.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kode dan Nama skema wajib diisi!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final result = await _skemaService.createSkema(
                code: code,
                name: name,
                description: desc,
                durasi: durasi,
              );

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skema berhasil ditambahkan ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Gagal tambah skema'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
  void _showEditDialog(Map<String, dynamic> skema) {
    final codeController = TextEditingController(text: skema['code'] ?? '');
    final nameController = TextEditingController(text: skema['name'] ?? '');
    final descController = TextEditingController(text: skema['description'] ?? '');
    final durasiController = TextEditingController(
      text: skema['durasi']?.toString() ?? '120',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Skema Sertifikasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Skema *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Skema *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durasiController,
                decoration: const InputDecoration(
                  labelText: 'Durasi Ujian (menit)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
              final code = codeController.text.trim();
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final durasi = int.tryParse(durasiController.text.trim()) ?? 120;

              if (code.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kode dan Nama skema wajib diisi!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final result = await _skemaService.updateSkema(
                id: skema['id'],
                data: {
                  'code': code,
                  'name': name,
                  'description': desc,
                  'durasi': durasi,
                },
              );

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skema berhasil diupdate ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Gagal update skema'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE SKEMA
  // ============================================================
  Future<void> _deleteSkema(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Skema'),
        content: Text('Apakah Anda yakin ingin menghapus skema "$name"?'),
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
      final result = await _skemaService.deleteSkema(id);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skema berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal hapus skema'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Kelola Skema',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================================
          // SEARCH
          // ============================================================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari skema...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _searchSkema,
            ),
          ),

          // ============================================================
          // STATS
          // ============================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildStatsChip('Total', _skemaList.length, Colors.blue),
                const SizedBox(width: 8),
                _buildStatsChip('Aktif', 
                    _skemaList.length, // TODO: Filter aktif
                    Colors.green),
              ],
            ),
          ),

          // ============================================================
          // LIST SKEMA
          // ============================================================
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredList.isEmpty
                    ? EmptyState(
                        icon: Icons.category_outlined,
                        title: 'Tidak ada skema',
                        subtitle: 'Belum ada skema sertifikasi yang dibuat',
                        buttonText: 'Tambah Skema',
                        onButtonPressed: _showAddDialog,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final item = _filteredList[index];
                          final id = item['id'] ?? '';
                          final code = item['code'] ?? '-';
                          final name = item['name'] ?? '-';
                          final description = item['description'] ?? '-';
                          final durasi = item['durasi'] ?? 0;

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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          code,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '⏱ $durasi menit',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (description != '-' && description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
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
                                          _deleteSkema(id, name);
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
        onPressed: _showAddDialog,
        backgroundColor: Colors.orange,
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
}