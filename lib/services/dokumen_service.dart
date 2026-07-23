import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class DokumenService {
  final _supabase = SupabaseConfig.client;

  // ============================================================
  // UPLOAD DOKUMEN
  // ============================================================
  Future<Map<String, dynamic>> uploadDokumen({
    required String pesertaId,
    required String jenisDokumen, // 'ktp', 'ijazah', 'skor'
    required File file,
  }) async {
    try {
      // 1. Upload file ke Supabase Storage
      final fileName = '${pesertaId}_${jenisDokumen}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      final filePath = 'dokumen/$fileName';

      // ✅ PERBAIKAN: upload() mengembalikan String, bukan response object
      final uploadedPath = await _supabase.storage
          .from('dokumen')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // 2. Dapatkan public URL
      final publicUrl = _supabase.storage
          .from('dokumen')
          .getPublicUrl(uploadedPath);

      // 3. Update kolom dokumen di tabel peserta
      String columnName;
      switch (jenisDokumen.toLowerCase()) {
        case 'ktp':
          columnName = 'dokumen_ktp';
          break;
        case 'ijazah':
          columnName = 'dokumen_ijazah';
          break;
        case 'skor':
          columnName = 'dokumen_skor';
          break;
        default:
          return {
            'success': false,
            'message': 'Jenis dokumen tidak valid',
          };
      }

      final updateResponse = await _supabase
          .from('peserta')
          .update({columnName: publicUrl})
          .eq('id', pesertaId)
          .select()
          .maybeSingle();

      if (updateResponse != null) {
        return {
          'success': true,
          'message': 'Dokumen berhasil diupload',
          'data': {
            'url': publicUrl,
            'file_path': uploadedPath,
            'peserta': updateResponse,
          },
        };
      }

      return {
        'success': false,
        'message': 'Gagal update data peserta',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // UPLOAD MULTIPLE DOKUMEN
  // ============================================================
  Future<Map<String, dynamic>> uploadMultipleDokumen({
    required String pesertaId,
    required Map<String, File> documents, // {'ktp': file1, 'ijazah': file2}
  }) async {
    try {
      final results = <String, dynamic>{};
      bool allSuccess = true;
      String errorMessage = '';

      for (var entry in documents.entries) {
        final result = await uploadDokumen(
          pesertaId: pesertaId,
          jenisDokumen: entry.key,
          file: entry.value,
        );

        results[entry.key] = result;
        if (!result['success']) {
          allSuccess = false;
          errorMessage = result['message'];
          break;
        }
      }

      return {
        'success': allSuccess,
        'message': allSuccess ? 'Semua dokumen berhasil diupload' : errorMessage,
        'results': results,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // GET DOKUMEN PESERTA
  // ============================================================
  Future<Map<String, dynamic>?> getDokumenPeserta(String pesertaId) async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('dokumen_ktp, dokumen_ijazah, dokumen_skor')
          .eq('id', pesertaId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // HAPUS DOKUMEN
  // ============================================================
  Future<Map<String, dynamic>> deleteDokumen({
    required String pesertaId,
    required String jenisDokumen,
  }) async {
    try {
      // 1. Ambil nama file dari URL
      final response = await _supabase
          .from('peserta')
          .select('dokumen_ktp, dokumen_ijazah, dokumen_skor')
          .eq('id', pesertaId)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Peserta tidak ditemukan',
        };
      }

      String columnName;
      String? url;
      switch (jenisDokumen.toLowerCase()) {
        case 'ktp':
          columnName = 'dokumen_ktp';
          url = response['dokumen_ktp'];
          break;
        case 'ijazah':
          columnName = 'dokumen_ijazah';
          url = response['dokumen_ijazah'];
          break;
        case 'skor':
          columnName = 'dokumen_skor';
          url = response['dokumen_skor'];
          break;
        default:
          return {
            'success': false,
            'message': 'Jenis dokumen tidak valid',
          };
      }

      if (url == null || url.isEmpty) {
        return {
          'success': false,
          'message': 'Dokumen tidak ditemukan',
        };
      }

      // 2. Hapus dari Storage (ambil nama file dari URL)
      final path = url.split('/').last;
      await _supabase.storage.from('dokumen').remove([path]);

      // 3. Update kolom menjadi null
      await _supabase
          .from('peserta')
          .update({columnName: null})
          .eq('id', pesertaId);

      return {
        'success': true,
        'message': 'Dokumen berhasil dihapus',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // GET STATUS VERIFIKASI DOKUMEN
  // ============================================================
  Future<Map<String, dynamic>> getStatusVerifikasi(String pesertaId) async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('dokumen_ktp, dokumen_ijazah, dokumen_skor')
          .eq('id', pesertaId)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Peserta tidak ditemukan',
        };
      }

      final status = {
        'ktp': response['dokumen_ktp'] != null ? 'uploaded' : 'empty',
        'ijazah': response['dokumen_ijazah'] != null ? 'uploaded' : 'empty',
        'skor': response['dokumen_skor'] != null ? 'uploaded' : 'empty',
      };

      final total = status.values.where((s) => s == 'uploaded').length;

      return {
        'success': true,
        'data': status,
        'total': total,
        'lengkap': total == 3,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // VERIFIKASI DOKUMEN OLEH ADMIN
  // ============================================================
  Future<Map<String, dynamic>> verifikasiDokumen({
    required String pesertaId,
    required bool status,
    String? catatan,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (catatan != null) {
        updateData['dokumen_catatan'] = catatan;
      }

      if (status) {
        // Jika lolos verifikasi, update status peserta
        updateData['status'] = 'verifikasi';
      } else {
        updateData['status'] = 'pending';
      }

      final response = await _supabase
          .from('peserta')
          .update(updateData)
          .eq('id', pesertaId)
          .select()
          .maybeSingle();

      if (response != null) {
        return {
          'success': true,
          'message': status ? 'Dokumen diverifikasi ✅' : 'Dokumen ditolak ❌',
          'data': response,
        };
      }

      return {
        'success': false,
        'message': 'Gagal verifikasi dokumen',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // DOWNLOAD DOKUMEN
  // ============================================================
  Future<Map<String, dynamic>> downloadDokumen({
    required String url,
    required String fileName,
  }) async {
    try {
      // Download dari Supabase Storage
      final path = url.split('/').last;
      final response = await _supabase.storage
          .from('dokumen')
          .download(path);

      // ✅ PERBAIKAN: response adalah List<int> atau null

      return {
        'success': true,
        'data': response,
        'message': 'Dokumen berhasil di download',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // GET DAFTAR DOKUMEN PENDING
  // ============================================================
  Future<List<Map<String, dynamic>>> getDokumenPending() async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              id,
              nik,
              status,
              dokumen_ktp,
              dokumen_ijazah,
              dokumen_skor,
              users!peserta_user_id_fkey (
                  id,
                  name,
                  email
              )
          ''')
          .or('dokumen_ktp.is.not.null,dokumen_ijazah.is.not.null,dokumen_skor.is.not.null')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ============================================================
  // CEK VALIDASI DOKUMEN
  // ============================================================
  Map<String, dynamic> validasiDokumen({
    required File file,
    required String jenisDokumen,
    int maxSizeMB = 5,
    List<String> allowedFormats = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) {
    try {
      // Cek ukuran file
      final sizeInMB = file.lengthSync() / (1024 * 1024);
      if (sizeInMB > maxSizeMB) {
        return {
          'valid': false,
          'message': 'Ukuran file maksimal $maxSizeMB MB',
        };
      }

      // Cek format file
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedFormats.contains(extension)) {
        return {
          'valid': false,
          'message': 'Format file tidak didukung. Gunakan: ${allowedFormats.join(', ')}',
        };
      }

      return {
        'valid': true,
        'message': 'Dokumen valid',
        'info': {
          'size': sizeInMB.toStringAsFixed(2),
          'format': extension,
          'name': file.path.split('/').last,
        },
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ============================================================
  // CEK FILE EXIST DI STORAGE
  // ============================================================
  Future<bool> checkFileExists(String url) async {
    try {
      final path = url.split('/').last;
      final response = await _supabase.storage
          .from('dokumen')
          .download(path);

      // ignore: unnecessary_null_comparison
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // GET PUBLIC URL
  // ============================================================
  String getPublicUrl(String path) {
    return _supabase.storage.from('dokumen').getPublicUrl(path);
  }

  // ============================================================
  // GET ALL DOKUMEN PESERTA (DENGAN DETAIL)
  // ============================================================
  Future<Map<String, dynamic>> getDokumenDetail(String pesertaId) async {
    try {
      final response = await _supabase
          .from('peserta')
          .select('''
              id,
              nik,
              status,
              dokumen_ktp,
              dokumen_ijazah,
              dokumen_skor,
              users!peserta_user_id_fkey (
                  id,
                  name,
                  email
              )
          ''')
          .eq('id', pesertaId)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Peserta tidak ditemukan',
        };
      }

      // Cek status verifikasi
      final statusVerifikasi = {
        'ktp': {
          'uploaded': response['dokumen_ktp'] != null,
          'url': response['dokumen_ktp'],
        },
        'ijazah': {
          'uploaded': response['dokumen_ijazah'] != null,
          'url': response['dokumen_ijazah'],
        },
        'skor': {
          'uploaded': response['dokumen_skor'] != null,
          'url': response['dokumen_skor'],
        },
      };

      return {
        'success': true,
        'data': response,
        'dokumen': statusVerifikasi,
        'total_terupload': statusVerifikasi.values.where((v) => v['uploaded'] == true).length,
        'lengkap': statusVerifikasi.values.every((v) => v['uploaded'] == true),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}