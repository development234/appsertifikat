import '../config/supabase_config.dart';

class JadwalService {
  final _supabase = SupabaseConfig.client;

  // ============================================================
  // GET SEMUA JADWAL
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllJadwal() async {
    try {
      final response = await _supabase
          .from('jadwal')
          .select('''
              *,
              skema!jadwal_skema_id_fkey (
                  id,
                  code,
                  name
              )
          ''')
          .order('tanggal', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET JADWAL BY ID
  // ============================================================
  Future<Map<String, dynamic>?> getJadwalById(String id) async {
    try {
      final response = await _supabase
          .from('jadwal')
          .select('''
              *,
              skema!jadwal_skema_id_fkey (
                  id,
                  code,
                  name
              )
          ''')
          .eq('id', id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // CREATE JADWAL
  // ============================================================
  Future<Map<String, dynamic>> createJadwal({
    required String skemaId,
    required String tanggal,
    required String waktuMulai,
    required String waktuSelesai,
    required int kuota,
    required String lokasi,
  }) async {
    try {
      final response = await _supabase.from('jadwal').insert({
        'skema_id': skemaId,
        'tanggal': tanggal,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        'kuota': kuota,
        'lokasi': lokasi,
        'status': 'open',
      }).select().maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal menambahkan jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================================
  // UPDATE JADWAL
  // ============================================================
  Future<Map<String, dynamic>> updateJadwal({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from('jadwal')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal update jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================================
  // DELETE JADWAL
  // ============================================================
  Future<Map<String, dynamic>> deleteJadwal(String id) async {
    try {
      await _supabase.from('jadwal').delete().eq('id', id);
      return {'success': true, 'message': 'Jadwal berhasil dihapus'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================================
  // UPDATE STATUS JADWAL
  // ============================================================
  Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from('jadwal')
          .update({'status': status})
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal update status'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============================================================
  // GET JADWAL OPEN
  // ============================================================
  Future<List<Map<String, dynamic>>> getJadwalOpen() async {
    try {
      final response = await _supabase
          .from('jadwal')
          .select('''
              *,
              skema!jadwal_skema_id_fkey (
                  id,
                  code,
                  name
              )
          ''')
          .eq('status', 'open')
          .gte('tanggal', DateTime.now().toIso8601String().split('T')[0])
          .order('tanggal', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}