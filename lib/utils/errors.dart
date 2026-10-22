import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';

/// Mengubah error teknis menjadi pesan bahasa Indonesia untuk pengguna.
String friendlyError(Object error) {
  if (error is AppException) return error.message;

  if (error is AuthException) {
    final m = error.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'Email atau password salah';
    if (m.contains('email not confirmed')) return 'Email belum dikonfirmasi. Cek kotak masuk emailmu.';
    if (m.contains('already registered') || m.contains('already been registered')) return 'Email sudah terdaftar';
    if (m.contains('expired') || m.contains('token') || (m.contains('invalid') && m.contains('otp'))) {
      return 'Kode salah atau sudah kedaluwarsa';
    }
    if (m.contains('should be different')) return 'Password baru harus berbeda dari password lama';
    if (m.contains('password should be at least')) return 'Password terlalu pendek';
    if (m.contains('rate limit') || m.contains('security purposes')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    }
    return error.message;
  }

  if (error is PostgrestException) {
    // Pesan dari fungsi database (mis. "Stok tidak cukup: ...") sudah berbahasa Indonesia.
    final m = error.message;
    if (m.startsWith('Stok tidak cukup') ||
        m.startsWith('Keranjang masih kosong') ||
        m.startsWith('Alamat') ||
        m.startsWith('Belum login') ||
        m.startsWith('Hanya admin') ||
        m.startsWith('Pesanan tidak ditemukan') ||
        m.startsWith('Status tidak dikenal')) {
      return m;
    }
    return 'Gagal memproses data. Coba lagi.';
  }

  if (error is StorageException) {
    final m = error.message.toLowerCase();
    if (m.contains('bucket not found')) {
      return 'Penyimpanan foto belum disiapkan. Jalankan SQL foto di Supabase.';
    }
    if (m.contains('row-level security') || m.contains('unauthorized') || error.statusCode == '403') {
      return 'Tidak diizinkan mengunggah foto (aturan Storage Supabase).';
    }
    if (m.contains('payload too large') || m.contains('exceeded the maximum')) return 'Ukuran foto terlalu besar';
    return 'Gagal mengunggah foto: ${error.message}';
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') || text.contains('failed host lookup') || text.contains('network')) {
    return 'Tidak ada koneksi internet';
  }
  return 'Terjadi kesalahan. Coba lagi.';
}
