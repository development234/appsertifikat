import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class JadwalUjian extends StatefulWidget {
  const JadwalUjian({super.key});

  @override
  State<JadwalUjian> createState() => _JadwalUjianState();
}

class _JadwalUjianState extends State<JadwalUjian> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _jadwalList = [];

  final _supabase = SupabaseConfig.client;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('jadwal')
          .select('''
              *,
              skema!inner (
                  name,
                  code
              )
          ''')
          .eq('pakar_id', user.id)
          .order('tanggal', ascending: true);

      setState(() {
        _jadwalList = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Jadwal Ujian',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _jadwalList.isEmpty
                        ? const Center(
                            child: Text('Belum ada jadwal ujian'),
                          )
                        : ListView.builder(
                            itemCount: _jadwalList.length,
                            itemBuilder: (context, index) {
                              final item = _jadwalList[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item['skema']?['name'] ?? '-'),
                                  subtitle: Text(item['tanggal'] ?? '-'),
                                  trailing: Text(item['status'] ?? ''),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}