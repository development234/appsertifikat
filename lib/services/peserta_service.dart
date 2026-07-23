import '../config/supabase_config.dart';

class PesertaService {
  final _supabase = SupabaseConfig.client;

  // ============================================================
  // GET SEMUA PESERTA
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllPeserta() async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              *,
              users!peserta_user_id_fkey (
                  id,
                  email,
                  name
              ),
              skema!peserta_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET PESERTA BY ID
  // ============================================================
  Future<Map<String, dynamic>?> getPesertaById(String id) async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              *,
              users!peserta_user_id_fkey (
                  id,
                  email,
                  name
              ),
              skema!peserta_skema_id_fkey (
                  id,
                  name,
                  code
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
  // CREATE PESERTA
  // ============================================================
  Future<Map<String, dynamic>> createPeserta({
    required String userId,
    required String nik,
    required String phone,
    required String address,
    String? skemaId,
  }) async {
    try {
      final response = await _supabase.from('peserta').insert({
        'user_id': userId,
        'nik': nik,
        'phone': phone,
        'address': address,
        'skema_id': skemaId,
        'status': 'pending',
      }).select().maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal menambahkan peserta'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // UPDATE PESERTA
  // ============================================================
  Future<Map<String, dynamic>> updatePeserta({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from('peserta')
          .update(data)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal update peserta'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // DELETE PESERTA
  // ============================================================
  Future<Map<String, dynamic>> deletePeserta(String id) async {
    try {
      await _supabase.from('peserta').delete().eq('id', id);
      return {'success': true, 'message': 'Peserta berhasil dihapus'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // UPDATE STATUS PESERTA
  // ============================================================
  Future<Map<String, dynamic>> updateStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _supabase
          .from('peserta')
          .update({'status': status})
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {'success': true, 'data': response};
      }
      return {'success': false, 'message': 'Gagal update status'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================================
  // SEARCH PESERTA
  // ============================================================
  Future<List<Map<String, dynamic>>> searchPeserta(String keyword) async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              *,
              users!peserta_user_id_fkey (
                  id,
                  email,
                  name
              ),
              skema!peserta_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .or('nik.ilike.%$keyword%,users.name.ilike.%$keyword%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}