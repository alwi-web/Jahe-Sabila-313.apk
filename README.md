# Jahe Merah Sabila 313 — Aplikasi Pembeli & Admin (Flutter + Supabase)

Satu aplikasi mobile untuk dua peran, dengan layar Masuk yang sama:

- **Pembeli**: registrasi, lupa password dengan kode 6 digit, katalog 3 varian,
  ukuran 250 g / 500 g / 1 kg, keranjang, checkout ke WhatsApp, riwayat pesanan,
  profil, ubah password, dan alamat.
- **Admin**: Beranda (ringkasan), Pesanan (cari, filter, detail, ubah status,
  hubungi WhatsApp, batalkan), Produk (tambah, ubah, hapus, harga & stok per ukuran),
  Laporan (bulan ini / bulan lalu / semua, unduh PDF dan Excel).

Setelah login, aplikasi membaca peran akun dari kolom `profiles.role` di Supabase:
`admin` membuka dashboard admin, selain itu membuka katalog pembeli.
Data disimpan di **Supabase**.

## Unduh APK

Setiap push ke `main` membangun APK baru dan menerbitkannya di halaman **Releases**.
APK terbaru selalu bisa diunduh langsung di:

https://github.com/alwi-web/Jahe-Sabila-313.apk/releases/latest/download/sabila313.apk

## 1. Menjalankan (mode demo, tanpa Supabase)

Butuh Flutter 3.22 atau lebih baru.

```bash
cd sabila313
flutter create . --platforms=android,ios --org com.sabila313   # membuat folder android/ios
flutter pub get
flutter run
```

Selama `lib/config.dart` belum diisi, aplikasi berjalan dalam **mode demo**:
semua fitur bisa dicoba, tapi data hanya di memori dan hilang saat aplikasi ditutup.
Di mode demo, kode reset 6 digit apa pun diterima, dan email `admin@...`
(misalnya `admin@sabila313.com`) dianggap admin. Coba: daftar sebagai pembeli,
pesan sesuatu, keluar, lalu masuk dengan `admin@sabila313.com` untuk melihat
pesanan itu di dashboard admin.

Uji logika (keranjang, alamat, checkout, ubah password, admin):

```bash
flutter test
```

## 2. Menyiapkan Supabase

1. Buat proyek di https://supabase.com (paket gratis cukup).
2. **SQL Editor → New query**, tempel seluruh isi `supabase/schema.sql`, lalu **Run**.
   Kalau `schema.sql` versi sebelumnya sudah pernah dijalankan, cukup jalankan
   `supabase/migrasi_admin.sql` (fungsi status pesanan + penyimpanan foto produk).
   File ini aman dijalankan ulang.
   Ini membuat tabel sesuai ERD, aturan keamanan (RLS), fungsi checkout, dan
   data 3 varian beserta harganya.
3. **Authentication → Email Templates → Reset Password**: ganti isi email supaya
   menampilkan kode, misalnya:
   ```html
   <h2>Kode reset password Sabila 313</h2>
   <p>Masukkan kode ini di aplikasi: <strong>{{ .Token }}</strong></p>
   <p>Kode berlaku sebentar. Abaikan email ini kalau kamu tidak memintanya.</p>
   ```
   Pastikan panjang kode email (Email OTP length) 6 digit di
   **Authentication → Providers → Email**.
4. (Opsional, untuk uji cepat) **Authentication → Providers → Email**: matikan
   *Confirm email* supaya akun baru bisa langsung masuk tanpa klik link konfirmasi.
5. **Project Settings → API**: salin *Project URL* dan *anon public key* ke
   `lib/config.dart`, lalu isi juga nomor WhatsApp toko:
   ```dart
   const supabaseUrl = 'https://abcdxyz.supabase.co';
   const supabaseAnonKey = 'eyJhbGciOi...';
   const sellerWhatsApp = '6281234567890';
   ```
6. Jalankan ulang aplikasi. Sekarang data tersimpan di Supabase.

**Membuat akun admin:** daftar dulu lewat aplikasi seperti pembeli biasa, lalu di SQL Editor:
```sql
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'email-admin@contoh.com');
```

## Push notification (Firebase)

Admin mendapat notifikasi saat ada pesanan baru; pembeli saat status atau resi pesanannya berubah
(termasuk batal otomatis). Konfigurasi Firebase proyek `sabila313` ada di `lib/firebase_options.dart`.

1. **SQL Editor**: jalankan `supabase/migrasi_notifikasi.sql` (tabel token HP).
2. **Edge Functions → Deploy a new function → Via Editor**: nama `kirim-notif`, tempel isi
   `supabase/functions/kirim-notif/index.ts`, lalu Deploy.
3. **Edge Functions → Secrets**: tambahkan `FCM_SERVICE_ACCOUNT` berisi seluruh isi file JSON
   service account Firebase (Firebase Console → Project settings → Service accounts →
   Generate new private key). Jangan simpan file itu di repo.
4. **Database → Webhooks → Create a new hook**: tabel `pesanan`, event **Insert** dan **Update**,
   tipe **Supabase Edge Functions**, fungsi `kirim-notif`, metode POST, dengan header auth service key.

## 3. Pengaturan Android

Di `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <application ...> ... </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
</manifest>
```

## Pengaturan iOS (foto produk)

Admin memilih foto dari galeri atau kamera (paket `image_picker`). Di
`ios/Runner/Info.plist` tambahkan:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Untuk memilih foto produk.</string>
<key>NSCameraUsageDescription</key>
<string>Untuk memotret produk.</string>
```

Android tidak perlu izin tambahan.

## Struktur

```
supabase/schema.sql          tabel, RLS, fungsi buat_pesanan & set_alamat_utama, data awal
lib/
  main.dart                  pilih Supabase atau mode demo, pulihkan sesi login
  config.dart                URL & key Supabase, nomor WhatsApp toko
  theme.dart                 warna dan gaya (sama dengan desain)
  data/
    models.dart              Product, Variant, CartItem, Order, Address, UserProfile
    repository.dart          antarmuka akses data
    supabase_repository.dart implementasi Supabase
    memory_repository.dart   implementasi mode demo / uji
    app_state.dart           state bersama: akun, produk, keranjang, pesanan, alamat
  utils/                     format rupiah & tanggal, WhatsApp, pesan error
  widgets/common.dart        komponen bersama
  screens/                   auth, home, catalog, cart, account
```

## Cara kerja data

| Fitur | Di Supabase |
|---|---|
| Daftar | `auth.signUp`; nama & no HP disalin ke `profiles` oleh trigger |
| Lupa password | `resetPasswordForEmail` → email berisi kode → `verifyOTP(recovery)` → `updateUser(password)` → keluar, wajib login ulang |
| Ubah password (sudah login) | cek password lama dengan masuk ulang, lalu `updateUser(password)` |
| Produk & harga | tabel `produk` + `varian_produk` (harga per ukuran) |
| Keranjang | tabel `keranjang`, satu baris per varian, tersimpan per akun |
| Alamat | tabel `alamat`, satu `is_utama` per pengguna (`set_alamat_utama`) |
| Checkout | fungsi `buat_pesanan`: cek alamat & stok, simpan `pesanan` + `detail_pesanan` dengan harga saat itu, kurangi stok, kosongkan keranjang; lalu WhatsApp dibuka |
| Peran akun | `profiles.role` (`admin`/`pembeli`); pembeli tidak bisa mengubahnya sendiri |
| Status pesanan | admin memanggil fungsi `ubah_status_pesanan`; pembatalan mengembalikan stok, mencabut pembatalan memotong stok lagi. Pembeli menarik layar Riwayat ke bawah untuk melihat status terbaru |
| Produk (admin) | tambah/ubah `produk` + `varian_produk` (upsert per ukuran); "hapus" = `aktif = false`, jadi riwayat pesanan lama tetap utuh |
| Foto produk | diunggah ke Supabase Storage bucket `produk` (hanya admin yang boleh), URL disimpan di `produk.gambar`; tampil di katalog, detail, keranjang, dan daftar produk admin. Tanpa foto, dipakai gambar kemasan |
| Laporan (admin) | dihitung dari pesanan: pendapatan = pesanan Selesai; unduh PDF (paket `pdf`/`printing`) dan Excel (paket `excel`, dibagikan lewat `share_plus`) |

Catatan:
- Stok (`varian_produk.stok`) boleh kosong (`null`) berarti tidak dihitung.
  Kalau diisi, checkout menolak pesanan yang melebihi stok, dan stok dikurangi
  saat pesanan dibuat. Kalau admin membatalkan pesanan, stoknya dikembalikan.
- Pembeli tidak bisa mengubah status pesanan atau menjadikan dirinya admin (dijaga RLS).
