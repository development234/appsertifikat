import '../config/supabase_config.dart';

class SertifikatService {
  final _supabase = SupabaseConfig.client;

  // ============================================================
  // GET SEMUA SERTIFIKAT
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllSertifikat() async {
    try {
      final response = await _supabase
          .from('sertifikat')
          .select('''
              *,
              peserta!sertifikat_peserta_id_fkey (
                  id,
                  nik,
                  users!peserta_user_id_fkey (
                      id,
                      name,
                      email
                  )
              ),
              skema!sertifikat_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .order('tanggal_terbit', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET PESERTA LULUS
  // ============================================================
  Future<List<Map<String, dynamic>>> getPesertaLulus() async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              id,
              nik,
              users!peserta_user_id_fkey (
                  id,
                  name,
                  email
              ),
              skema!peserta_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .eq('status', 'lulus');

      // Filter yang belum punya sertifikat
      final results = <Map<String, dynamic>>[];
      for (var item in response) {
        final sertifikat = await _supabase
            .from('sertifikat')
            .select('id')
            .eq('peserta_id', item['id'])
            .eq('status', 'active')
            .maybeSingle();

        if (sertifikat == null) {
          results.add(item);
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // TERBITKAN SERTIFIKAT
  // ============================================================
  Future<Map<String, dynamic>> terbitkanSertifikat({
    required String pesertaId,
  }) async {
    try {
      // Cek apakah sudah ada sertifikat aktif
      final existing = await _supabase
          .from('sertifikat')
          .select('id')
          .eq('peserta_id', pesertaId)
          .eq('status', 'active')
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'message': 'Peserta sudah memiliki sertifikat aktif',
        };
      }

      // Ambil data peserta
      final peserta = await _supabase
          .from('peserta')
          .select('''
              skema_id,
              users!peserta_user_id_fkey (
                  name
              )
          ''')
          .eq('id', pesertaId)
          .maybeSingle();

      if (peserta == null) {
        return {
          'success': false,
          'message': 'Peserta tidak ditemukan',
        };
      }

      // Generate nomor sertifikat
      final nomorSertifikat = _generateNomorSertifikat(peserta);

      // Insert sertifikat
      final response = await _supabase.from('sertifikat').insert({
        'peserta_id': pesertaId,
        'skema_id': peserta['skema_id'],
        'nomor_sertifikat': nomorSertifikat,
        'tanggal_terbit': DateTime.now().toIso8601String().split('T')[0],
        'status': 'active',
      }).select().maybeSingle();

      if (response != null) {
        return {
          'success': true,
          'data': response,
          'message': 'Sertifikat berhasil diterbitkan',
        };
      }

      return {
        'success': false,
        'message': 'Gagal menerbitkan sertifikat',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // GENERATE NOMOR SERTIFIKAT
  // ============================================================
  String _generateNomorSertifikat(Map<String, dynamic> peserta) {
    final user = peserta['users'] as Map? ?? {};
    final name = user['name'] ?? 'UNKNOWN';
    final initials = name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join('').toUpperCase();
    final date = DateTime.now();
    final year = date.year;
    final random = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();

    return 'SERT-${year}-${initials}-$random';
  }

  // ============================================================
  // BATALKAN SERTIFIKAT
  // ============================================================
  Future<Map<String, dynamic>> batalkanSertifikat(String id) async {
    try {
      final response = await _supabase
          .from('sertifikat')
          .update({'status': 'cancelled'})
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return {
          'success': true,
          'data': response,
          'message': 'Sertifikat berhasil dibatalkan',
        };
      }

      return {
        'success': false,
        'message': 'Gagal membatalkan sertifikat',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // GET SERTIFIKAT BY PESERTA
  // ============================================================
  Future<List<Map<String, dynamic>>> getSertifikatByPeserta(String pesertaId) async {
    try {
      final response = await _supabase
          .from('sertifikat')
          .select('''
              *,
              skema!sertifikat_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .eq('peserta_id', pesertaId)
          .order('tanggal_terbit', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // GET SERTIFIKAT BY NOMOR
  // ============================================================
  Future<Map<String, dynamic>?> getSertifikatByNomor(String nomor) async {
    try {
      final response = await _supabase
          .from('sertifikat')
          .select('''
              *,
              peserta!sertifikat_peserta_id_fkey (
                  id,
                  nik,
                  users!peserta_user_id_fkey (
                      id,
                      name,
                      email
                  )
              ),
              skema!sertifikat_skema_id_fkey (
                  id,
                  name,
                  code
              )
          ''')
          .eq('nomor_sertifikat', nomor)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}