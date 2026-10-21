/// Pengaturan proyek. Isi dari Supabase Dashboard > Project Settings > API.
///
/// Selama nilai di bawah masih contoh, aplikasi berjalan dalam MODE DEMO:
/// data disimpan di memori HP dan hilang saat aplikasi ditutup.
const supabaseUrl = 'https://paslqibvuumnpooubkyk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhc2xxaWJ2dXVtbnBvb3Via3lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1ODU2NzIsImV4cCI6MjEwODE2MTY3Mn0.dzsq65alJL_JZcVNEPqK8nRV-h6DjkRiO1_acE4ep8o';

/// Nomor WhatsApp penjual, format internasional tanpa tanda + dan tanpa 0 di depan.
/// Contoh: 6281234567890
const sellerWhatsApp = '62XXXXXXXXXXX';

bool get supabaseConfigured => !supabaseUrl.contains('XXXXXXXX') && !supabaseAnonKey.startsWith('ISI_');
