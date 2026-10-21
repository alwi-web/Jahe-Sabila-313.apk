/// Pengaturan proyek. Isi dari Supabase Dashboard > Project Settings > API.
///
/// Selama nilai di bawah masih contoh, aplikasi berjalan dalam MODE DEMO:
/// data disimpan di memori HP dan hilang saat aplikasi ditutup.
const supabaseUrl = 'https://XXXXXXXX.supabase.co';
const supabaseAnonKey = 'ISI_ANON_PUBLIC_KEY';

/// Nomor WhatsApp penjual, format internasional tanpa tanda + dan tanpa 0 di depan.
/// Contoh: 6281234567890
const sellerWhatsApp = '62XXXXXXXXXXX';

bool get supabaseConfigured => !supabaseUrl.contains('XXXXXXXX') && !supabaseAnonKey.startsWith('ISI_');
