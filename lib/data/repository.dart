import 'dart:typed_data';

import 'models.dart';

/// Satu baris keranjang seperti yang tersimpan di database.
typedef CartRow = ({String variantId, int qty});

/// Semua akses data lewat antarmuka ini. Ada dua implementasi:
/// - SupabaseRepository: data asli di Supabase.
/// - MemoryRepository: mode demo/uji, data di memori.
abstract class ShopRepository {
  // Akun
  /// Pengguna yang sesinya masih tersimpan, atau null kalau belum login.
  Future<UserProfile?> currentUser();
  Future<UserProfile> signIn(String email, String password);

  /// Mengembalikan null kalau akun harus dikonfirmasi lewat email dulu.
  Future<UserProfile?> signUp({required String name, required String email, required String phone, required String password});
  Future<void> signOut();

  /// Mengirim kode 6 digit untuk reset password ke email.
  Future<void> sendResetCode(String email);

  /// Memeriksa kode. Melempar error kalau salah atau kedaluwarsa.
  Future<void> verifyResetCode(String email, String code);

  /// Menyimpan password baru setelah kode terverifikasi, lalu keluar (wajib login ulang).
  Future<void> setNewPassword(String newPassword);

  /// Ubah password saat login. Mengembalikan false kalau password lama salah.
  Future<bool> changePassword(String email, String oldPassword, String newPassword);

  /// Mengembalikan true kalau email diganti dan perlu dikonfirmasi lewat email baru.
  Future<bool> updateProfile(UserProfile profile, {required String previousEmail});

  /// Mengunggah foto profil ([ext] = jpg/png), mengembalikan URL-nya.
  Future<String> uploadProfilePhoto(Uint8List bytes, String ext);
  Future<void> removeProfilePhoto();

  // Produk
  Future<List<Product>> fetchProducts();

  // Keranjang
  Future<List<CartRow>> fetchCart();

  /// Jumlah 0 atau kurang = baris dihapus.
  Future<void> setCartQty(String variantId, int qty);

  // Alamat
  Future<List<Address>> fetchAddresses();

  /// Menyimpan alamat baru atau perubahan, mengembalikan id-nya.
  Future<String> saveAddress(Address address);
  Future<void> setMainAddress(String id);
  Future<void> deleteAddress(String id);

  // Pesanan
  Future<List<Order>> fetchOrders();

  /// Membuat pesanan dari isi keranjang dan mengosongkan keranjang.
  Future<Order> placeOrder(String addressId);

  /// Membatalkan pesanan Menunggu bayar yang lewat 3 jam (stok dikembalikan).
  Future<void> expireUnpaidOrders();

  /// Pembeli sudah melihat perubahan status/resi pesanannya.
  Future<void> markOrdersRead();

  // ---------------- Admin ----------------
  /// 'admin' atau 'pembeli' (kolom profiles.role).
  Future<String> fetchRole();

  /// Semua pesanan dari semua pembeli, terbaru dulu, lengkap dengan nama dan no HP pembeli.
  Future<List<Order>> adminFetchOrders();
  Future<void> adminSetOrderStatus(String orderId, OrderStatus status);

  /// Nomor WhatsApp toko (format 62...) dari pengaturan toko; null kalau belum diatur.
  Future<String?> fetchStoreWhatsApp();
  Future<void> adminSaveStoreWhatsApp(String number);

  /// Menyimpan kurir dan nomor resi pengiriman pesanan.
  Future<void> adminSetShipping(String orderId, String courier, String trackingNumber);

  /// Menyimpan produk baru atau perubahan, termasuk harga dan stok tiap ukuran.
  Future<void> adminSaveProduct(ProductDraft draft);

  /// Menyembunyikan produk dari katalog (riwayat pesanan lama tetap utuh).
  Future<void> adminDeactivateProduct(String productId);
}

/// Error dengan pesan yang siap ditampilkan ke pengguna.
class AppException implements Exception {
  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}
