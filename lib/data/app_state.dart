import 'package:flutter/foundation.dart';

import '../config.dart';
import '../utils/errors.dart';
import '../utils/whatsapp.dart';
import 'models.dart';
import 'repository.dart';

/// State bersama aplikasi. Semua layar membaca dan mengubah data lewat kelas
/// ini, dan kelas ini menyimpan perubahan ke [repo] (Supabase atau mode demo).
class AppState extends ChangeNotifier {
  AppState(this.repo, {this.onError});

  final ShopRepository repo;

  /// Dipanggil dengan pesan siap tampil saat operasi latar belakang gagal.
  final void Function(String message)? onError;

  void _report(Object e) => onError?.call(friendlyError(e));

  // ---------------- Navigasi bawah ----------------
  /// Tab pembeli. Tamu (belum login) hanya bisa membuka Beranda dan Produk.
  static const tabHome = 0, tabProducts = 1, tabCart = 2, tabAccount = 3;
  int tab = tabHome;

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  // ---------------- Akun ----------------
  UserProfile? _user;
  bool get loggedIn => _user != null;

  /// Peran akun dari profiles.role: 'admin' atau 'pembeli'.
  String role = 'pembeli';
  bool get isAdmin => role == 'admin';

  /// Memuat data sesuai peran setelah login.
  Future<void> _afterLogin() async {
    role = await repo.fetchRole();
    await loadStoreSettings();
    if (isAdmin) {
      adminTab = 0;
      await loadProducts();
      await loadAdminOrders();
    } else {
      // Tab tidak diubah: tamu yang login dari halaman Produk tetap di Produk.
      await loadAll();
    }
  }
  UserProfile get profile => _user ?? UserProfile.empty;

  /// Dipanggil saat aplikasi dibuka: memulihkan sesi yang tersimpan.
  Future<bool> bootstrap() async {
    try {
      _user = await repo.currentUser();
      if (_user != null) {
        await _afterLogin();
      } else {
        // Tamu: tetap bisa melihat Beranda dan katalog produk.
        await loadStoreSettings();
        await loadProducts();
      }
    } catch (e) {
      _report(e);
    }
    notifyListeners();
    return loggedIn;
  }

  Future<void> loadAll() async {
    await loadProducts();
    await Future.wait([loadCart(), loadAddresses(), loadOrders()]);
  }

  Future<void> signIn(String email, String password) async {
    _user = await repo.signIn(email, password);
    await _afterLogin();
    notifyListeners();
  }

  /// Mengembalikan false kalau akun perlu dikonfirmasi lewat email dulu.
  Future<bool> signUp({required String name, required String email, required String phone, required String password}) async {
    _user = await repo.signUp(name: name, email: email, phone: phone, password: password);
    if (_user == null) return false;
    await _afterLogin();
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await repo.signOut();
    _clearSession();
  }

  void _clearSession() {
    _user = null;
    role = 'pembeli';
    adminOrders = [];
    _cart = [];
    _addresses = [];
    _orders = [];
    tab = tabHome;
    notifyListeners();
  }

  Future<void> sendResetCode(String email) => repo.sendResetCode(email);
  Future<void> verifyResetCode(String email, String code) => repo.verifyResetCode(email, code);

  /// Simpan password baru dari alur lupa password. Setelah ini wajib login ulang.
  Future<void> setNewPassword(String password) async {
    await repo.setNewPassword(password);
    _clearSession();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) =>
      repo.changePassword(profile.email, oldPassword, newPassword);

  /// Mengembalikan true kalau email baru perlu dikonfirmasi.
  Future<bool> updateProfile({required String name, required String email, required String phone}) async {
    final previousEmail = profile.email;
    final updated = UserProfile(id: profile.id, name: name, email: email, phone: phone);
    final needsConfirm = await repo.updateProfile(updated, previousEmail: previousEmail);
    _user = UserProfile(
      id: updated.id,
      name: name,
      email: needsConfirm ? previousEmail : email,
      phone: phone,
      photoUrl: profile.photoUrl,
      photoBytes: profile.photoBytes,
    );
    notifyListeners();
    return needsConfirm;
  }

  /// Mengganti foto profil; [ext] = jpg atau png.
  Future<void> changeProfilePhoto(Uint8List bytes, String ext) async {
    final url = await repo.uploadProfilePhoto(bytes, ext);
    final p = profile;
    if (url.isEmpty) {
      p.photoBytes = bytes; // mode demo: foto disimpan di memori
    } else {
      p
        ..photoUrl = url
        ..photoBytes = null;
    }
    notifyListeners();
  }

  Future<void> removeProfilePhoto() async {
    await repo.removeProfilePhoto();
    profile
      ..photoUrl = ''
      ..photoBytes = null;
    notifyListeners();
  }

  // ---------------- Produk ----------------
  List<Product> products = [];
  bool loadingProducts = false;

  Future<void> loadProducts() async {
    loadingProducts = true;
    notifyListeners();
    try {
      products = await repo.fetchProducts();
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }

  ({Product product, Variant variant})? _findVariant(String variantId) {
    for (final p in products) {
      for (final v in p.variants) {
        if (v.id == variantId) return (product: p, variant: v);
      }
    }
    return null;
  }

  Product? productById(String? id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------------- Keranjang ----------------
  List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);

  int get cartCount => _cart.fold(0, (sum, it) => sum + it.qty);
  int get cartTotal => _cart.fold(0, (sum, it) => sum + it.lineTotal);
  bool get cartEmpty => _cart.isEmpty;

  Future<void> loadCart() async {
    final rows = await repo.fetchCart();
    final items = <CartItem>[];
    for (final r in rows) {
      final found = _findVariant(r.variantId);
      if (found != null) items.add(CartItem(product: found.product, variant: found.variant, qty: r.qty));
    }
    _cart = items;
    notifyListeners();
  }

  /// Perubahan langsung tampil di layar, lalu disimpan ke server.
  /// Kalau gagal, keranjang dimuat ulang dari server dan pesan error ditampilkan.
  Future<void> _saveQty(String variantId, int qty) async {
    try {
      await repo.setCartQty(variantId, qty);
    } catch (e) {
      _report(e);
      try {
        await loadCart();
      } catch (_) {}
    }
  }

  Future<void> addToCart(Product product, Variant variant, int qty) async {
    final i = _cart.indexWhere((it) => it.key == variant.id);
    final newQty = (i >= 0 ? _cart[i].qty : 0) + qty;
    if (i >= 0) {
      _cart[i].qty = newQty;
    } else {
      _cart.add(CartItem(product: product, variant: variant, qty: newQty));
    }
    notifyListeners();
    await _saveQty(variant.id, newQty);
  }

  /// Menambah atau mengurangi jumlah. Jumlah 0 berarti barang dihapus.
  Future<void> changeQty(String key, int delta) async {
    final i = _cart.indexWhere((it) => it.key == key);
    if (i < 0) return;
    final newQty = _cart[i].qty + delta;
    if (newQty <= 0) {
      _cart.removeAt(i);
    } else {
      _cart[i].qty = newQty;
    }
    notifyListeners();
    await _saveQty(key, newQty);
  }

  Future<void> removeFromCart(String key) async {
    _cart.removeWhere((it) => it.key == key);
    notifyListeners();
    await _saveQty(key, 0);
  }

  // ---------------- Pesanan ----------------
  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);
  bool loadingOrders = false;

  Future<void> loadOrders() async {
    loadingOrders = true;
    notifyListeners();
    try {
      await _expireUnpaidOrders();
      _orders = await repo.fetchOrders();
    } finally {
      loadingOrders = false;
      notifyListeners();
    }
  }

  /// Menyimpan isi keranjang sebagai pesanan (status Menunggu bayar) di server,
  /// lalu mengosongkan keranjang. Dipanggil sebelum WhatsApp dibuka.
  Future<Order> placeOrder() async {
    final address = mainAddress;
    if (address == null) throw AppException('Tambahkan alamat pengiriman dulu');
    final order = await repo.placeOrder(address.id);
    _orders.insert(0, order);
    _cart = [];
    notifyListeners();
    // Stok bisa berubah setelah pesanan dibuat.
    loadProducts().catchError((Object e) => _report(e));
    return order;
  }

  /// "Pesan lagi": masukkan ulang isi pesanan lama ke keranjang dengan harga terbaru.
  /// Mengembalikan jumlah baris yang tidak tersedia lagi.
  Future<int> reorder(Order order) async {
    var missing = 0;
    for (final line in order.lines) {
      final product = productById(line.productId);
      final variant = product?.variantOf(line.size);
      if (product == null || variant == null) {
        missing++;
        continue;
      }
      await addToCart(product, variant, line.qty);
    }
    return missing;
  }

  // ---------------- Alamat ----------------
  List<Address> _addresses = [];
  List<Address> get addresses => List.unmodifiable(_addresses);

  Future<void> loadAddresses() async {
    _addresses = await repo.fetchAddresses();
    notifyListeners();
  }

  Address? get mainAddress {
    if (_addresses.isEmpty) return null;
    for (final a in _addresses) {
      if (a.isMain) return a;
    }
    return _addresses.first;
  }

  bool isMain(Address a) => mainAddress?.id == a.id;

  Address newAddressDraft() => Address(
        id: '',
        label: 'Rumah',
        recipient: profile.name,
        phone: profile.phone,
        street: '',
        city: '',
        postalCode: '',
      );

  /// Menyimpan alamat. Alamat pertama otomatis menjadi utama.
  Future<void> saveAddress(Address address, {required bool makeMain}) async {
    final wasMain = !address.isNew && isMain(address);
    final first = _addresses.isEmpty;
    final id = await repo.saveAddress(address);
    if (makeMain || first) {
      await repo.setMainAddress(id);
    } else if (wasMain) {
      // Sakelar utama dimatikan: pindahkan status utama ke alamat lain.
      final other = _addresses.where((a) => a.id != id).toList();
      if (other.isNotEmpty) await repo.setMainAddress(other.first.id);
    }
    await loadAddresses();
  }

  Future<void> setMainAddress(String id) async {
    await repo.setMainAddress(id);
    await loadAddresses();
  }

  // ---------------- Admin ----------------
  /// 0 = Beranda, 1 = Pesanan, 2 = Produk, 3 = Laporan.
  int adminTab = 0;

  void setAdminTab(int value) {
    adminTab = value;
    notifyListeners();
  }

  List<Order> adminOrders = [];
  bool loadingAdminOrders = false;

  /// Filter status di layar Pesanan admin (null = Semua). Bisa diatur dari Beranda.
  OrderStatus? adminOrderFilter;

  void openAdminOrders(OrderStatus? filter) {
    adminOrderFilter = filter;
    adminTab = 1;
    notifyListeners();
  }

  void setAdminOrderFilter(OrderStatus? filter) {
    adminOrderFilter = filter;
    notifyListeners();
  }

  Future<void> loadAdminOrders() async {
    loadingAdminOrders = true;
    notifyListeners();
    try {
      await _expireUnpaidOrders();
      adminOrders = await repo.adminFetchOrders();
    } finally {
      loadingAdminOrders = false;
      notifyListeners();
    }
  }

  /// Cadangan untuk jadwal otomatis di database: batalkan pesanan yang lewat batas bayar.
  Future<void> _expireUnpaidOrders() async {
    try {
      await repo.expireUnpaidOrders();
    } catch (e) {
      // Fungsi belum dibuat (SQL belum dijalankan): pesanan tetap dimuat.
      debugPrint('Batal otomatis tidak berjalan: $e');
    }
  }

  /// Jumlah pesanan pembeli yang status/resinya berubah sejak terakhir dilihat.
  int get unreadOrderUpdates => _orders.where((o) => o.hasUnreadUpdate).length;

  /// Dipanggil saat pembeli membuka Riwayat pesanan.
  Future<void> markOrdersRead() async {
    if (unreadOrderUpdates == 0) return;
    await repo.markOrdersRead();
    final now = DateTime.now();
    for (final o in _orders) {
      if (o.updatedAt != null) o.readAt = now;
    }
    notifyListeners();
  }

  int countByStatus(OrderStatus s) => adminOrders.where((o) => o.status == s).length;

  Future<void> setOrderStatus(Order order, OrderStatus status) async {
    await repo.adminSetOrderStatus(order.id, status);
    order.status = status;
    notifyListeners();
    // Pembatalan bisa mengubah stok.
    loadProducts().catchError((Object e) => _report(e));
  }

  // ---------------- Pengaturan toko ----------------
  /// Nomor WhatsApp tujuan pesanan pembeli. Awalnya dari config.dart,
  /// lalu diganti nilai di tabel pengaturan_toko kalau sudah diatur admin.
  String storeWhatsApp = sellerWhatsApp;

  Future<void> loadStoreSettings() async {
    try {
      final n = await repo.fetchStoreWhatsApp();
      if (n != null && n.isNotEmpty) storeWhatsApp = n;
    } catch (e) {
      // Tabel belum dibuat (SQL belum dijalankan): tetap pakai nomor dari config.dart.
      debugPrint('Pengaturan toko tidak terbaca: $e');
    }
  }

  /// Menyimpan nomor WhatsApp toko; 08xx otomatis diubah menjadi 628xx.
  Future<void> saveStoreWhatsApp(String input) async {
    final number = normalizeWhatsAppNumber(input);
    await repo.adminSaveStoreWhatsApp(number);
    storeWhatsApp = number;
    notifyListeners();
  }

  Future<void> setShipping(Order order, String courier, String trackingNumber) async {
    await repo.adminSetShipping(order.id, courier, trackingNumber);
    order.courier = courier;
    order.trackingNumber = trackingNumber;
    notifyListeners();
  }

  Future<void> saveProduct(ProductDraft draft) async {
    await repo.adminSaveProduct(draft);
    await loadProducts();
  }

  Future<void> deactivateProduct(String productId) async {
    await repo.adminDeactivateProduct(productId);
    await loadProducts();
  }

  Future<void> deleteAddress(String id) async {
    final wasMain = mainAddress?.id == id;
    await repo.deleteAddress(id);
    await loadAddresses();
    if (wasMain && _addresses.isNotEmpty) {
      await repo.setMainAddress(_addresses.first.id);
      await loadAddresses();
    }
  }
}
