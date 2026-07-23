import '../config/supabase_config.dart';

class SkemaService {
  final _supabase = SupabaseConfig.client;

  // ============================================================
  // GET SEMUA SKEMA
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllSkema() async {
    try {
      final response = await _supabase
          .from('skema')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET SKEMA BY ID
  // ============================================================
  Future<Map<String, dynamic>?> getSkemaById(String id) async {
    try {
      final response = await _supabase
          .from('skema')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // CREATE SKEMA
  // ============================================================
  Future<Map<String, dynamic>> createSkema({
    required String code,
    required String name,
    required String description,
    required int durasi,
  }) async {
    try {
      // Cek duplikat code
      final existing = await _supabase
          .from('skema')
          .select('code')
          .eq('code', code)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'message': 'Kode skema sudah terdaftar'};
      }

      final response = await _supabase.from('skema').insert({
        'code': code,
        'name': name,
        'description': description,
        'durasi': durasi,
      }).select().maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal menambahkan skema'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // UPDATE SKEMA
  // ============================================================
  Future<Map<String, dynamic>> updateSkema({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from('skema')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal update skema'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // DELETE SKEMA
  // ============================================================
  Future<Map<String, dynamic>> deleteSkema(String id) async {
    try {
      await _supabase.from('skema').delete().eq('id', id);
      return {'success': true, 'message': 'Skema berhasil dihapus'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}