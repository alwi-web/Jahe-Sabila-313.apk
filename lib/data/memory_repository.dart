import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';

/// Mode demo dan uji: data disimpan di memori, tanpa internet.
/// Dipakai otomatis kalau config.dart belum diisi.
class MemoryRepository implements ShopRepository {
  MemoryRepository({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;
  Future<void> _wait() => Future.delayed(latency);

  final Map<String, ({UserProfile profile, String password})> _accounts = {};
  UserProfile? _session;
  String? _pendingResetEmail;

  final List<CartRow> _cart = [];
  final List<Address> _addresses = [];
  final List<Order> _orders = [];
  int _nextAddressId = 1;
  int _nextOrderId = 1;

  late final List<Product> _products = [
    _product('1', 'Jahe Merah dengan Gula Pasir', 'Jahe merah dengan tambahan gula pasir.', const Color(0xFFB8412C),
        [28000, 55000, 105000]),
    _product('2', 'Jahe Merah dengan Gula Merah', 'Jahe merah dengan tambahan gula merah.', const Color(0xFF7A4A1E),
        [30000, 58000, 111000]),
    _product('3', 'Jahe Merah Tanpa Gula', 'Jahe merah murni, tanpa tambahan gula.', const Color(0xFF3F6B4F),
        [25000, 48000, 95000]),
  ];

  static Product _product(String id, String name, String desc, Color accent, List<int> prices) => Product(
        id: id,
        name: name,
        description: desc,
        accent: accent,
        variants: [
          for (var i = 0; i < PackSize.values.length; i++)
            Variant(id: '$id-${PackSize.values[i].name}', size: PackSize.values[i], price: prices[i]),
        ],
      );

  UserProfile get _me {
    final s = _session;
    if (s == null) throw AppException('Sesi berakhir, silakan masuk lagi');
    return s;
  }

  // ---------------- Akun ----------------
  @override
  Future<UserProfile?> currentUser() async => _session;

  @override
  Future<UserProfile> signIn(String email, String password) async {
    await _wait();
    final key = email.trim().toLowerCase();
    final acc = _accounts[key];
    if (acc == null) {
      // Mode demo: email baru langsung dibuatkan akun.
      final p = UserProfile(id: key, name: key.split('@').first, email: key, phone: '');
      _accounts[key] = (profile: p, password: password);
      return _session = p;
    }
    if (acc.password != password) throw AppException('Email atau password salah');
    return _session = acc.profile;
  }

  @override
  Future<UserProfile?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw AppException('Email sudah terdaftar');
    final p = UserProfile(id: key, name: name, email: key, phone: phone);
    _accounts[key] = (profile: p, password: password);
    return _session = p;
  }

  @override
  Future<void> signOut() async => _session = null;

  @override
  Future<void> sendResetCode(String email) async {
    await _wait();
    _pendingResetEmail = email.trim().toLowerCase();
  }

  @override
  Future<void> verifyResetCode(String email, String code) async {
    await _wait();
    // Mode demo: kode 6 digit apa pun diterima.
    if (code.length != 6) throw AppException('Kode salah atau sudah kedaluwarsa');
    _pendingResetEmail = email.trim().toLowerCase();
  }

  @override
  Future<void> setNewPassword(String newPassword) async {
    await _wait();
    final key = _pendingResetEmail;
    if (key != null && _accounts[key] != null) {
      _accounts[key] = (profile: _accounts[key]!.profile, password: newPassword);
    }
    _pendingResetEmail = null;
    _session = null;
  }

  @override
  Future<bool> changePassword(String email, String oldPassword, String newPassword) async {
    await _wait();
    final key = email.trim().toLowerCase();
    final acc = _accounts[key];
    if (acc == null || acc.password != oldPassword) return false;
    _accounts[key] = (profile: acc.profile, password: newPassword);
    return true;
  }

  @override
  Future<bool> updateProfile(UserProfile profile, {required String previousEmail}) async {
    await _wait();
    _me
      ..name = profile.name
      ..phone = profile.phone
      ..email = profile.email;
    return false;
  }

  // ---------------- Produk ----------------
  @override
  Future<List<Product>> fetchProducts() async {
    await _wait();
    return _products;
  }

  // ---------------- Keranjang ----------------
  @override
  Future<List<CartRow>> fetchCart() async => List.of(_cart);

  @override
  Future<void> setCartQty(String variantId, int qty) async {
    final i = _cart.indexWhere((r) => r.variantId == variantId);
    if (qty <= 0) {
      if (i >= 0) _cart.removeAt(i);
    } else if (i >= 0) {
      _cart[i] = (variantId: variantId, qty: qty);
    } else {
      _cart.add((variantId: variantId, qty: qty));
    }
  }

  // ---------------- Alamat ----------------
  @override
  Future<List<Address>> fetchAddresses() async => _addresses
      .map((a) => Address(
            id: a.id,
            label: a.label,
            recipient: a.recipient,
            phone: a.phone,
            street: a.street,
            city: a.city,
            postalCode: a.postalCode,
            note: a.note,
            isMain: a.isMain,
          ))
      .toList();

  @override
  Future<String> saveAddress(Address a) async {
    if (a.isNew) {
      final id = '${_nextAddressId++}';
      _addresses.add(Address(
        id: id,
        label: a.label,
        recipient: a.recipient,
        phone: a.phone,
        street: a.street,
        city: a.city,
        postalCode: a.postalCode,
        note: a.note,
      ));
      return id;
    }
    final i = _addresses.indexWhere((x) => x.id == a.id);
    if (i < 0) throw AppException('Alamat tidak ditemukan');
    final keepMain = _addresses[i].isMain;
    _addresses[i] = a..isMain = keepMain;
    return a.id;
  }

  @override
  Future<void> setMainAddress(String id) async {
    for (final a in _addresses) {
      a.isMain = a.id == id;
    }
  }

  @override
  Future<void> deleteAddress(String id) async => _addresses.removeWhere((a) => a.id == id);

  // ---------------- Pesanan ----------------
  @override
  Future<List<Order>> fetchOrders() async => List.of(_orders);

  @override
  Future<Order> placeOrder(String addressId) async {
    await _wait();
    final ai = _addresses.indexWhere((a) => a.id == addressId);
    if (ai < 0) throw AppException('Alamat pengiriman tidak ditemukan');
    final address = _addresses[ai];
    if (_cart.isEmpty) throw AppException('Keranjang masih kosong');
    final lines = <OrderLine>[];
    for (final row in _cart) {
      for (final p in _products) {
        for (final v in p.variants) {
          if (v.id == row.variantId) {
            lines.add(OrderLine(productName: p.name, productId: p.id, size: v.size, qty: row.qty, unitPrice: v.price));
          }
        }
      }
    }
    final order = Order(
      id: '${_nextOrderId++}',
      date: DateTime.now(),
      lines: lines,
      addressText: address.fullText,
      total: lines.fold(0, (s, l) => s + l.total),
      buyerName: _me.name,
      buyerPhone: _me.phone,
    );
    _orders.insert(0, order);
    _cart.clear();
    return order;
  }

  // ---------------- Admin ----------------
  /// Mode demo: akun dengan email admin atau admin@... dianggap admin.
  @override
  Future<String> fetchRole() async => _me.email.split('@').first.toLowerCase() == 'admin' ? 'admin' : 'pembeli';

  @override
  Future<List<Order>> adminFetchOrders() async {
    await _wait();
    return List.of(_orders);
  }

  @override
  Future<void> adminSetOrderStatus(String orderId, OrderStatus status) async {
    await _wait();
    for (final o in _orders) {
      if (o.id == orderId) o.status = status;
    }
  }

  String? _storeWhatsApp;

  @override
  Future<String?> fetchStoreWhatsApp() async => _storeWhatsApp;

  @override
  Future<void> adminSaveStoreWhatsApp(String number) async {
    await _wait();
    _storeWhatsApp = number;
  }

  @override
  Future<void> adminSetShipping(String orderId, String courier, String trackingNumber) async {
    await _wait();
    for (final o in _orders) {
      if (o.id == orderId) {
        o.courier = courier;
        o.trackingNumber = trackingNumber;
      }
    }
  }

  int _nextProductId = 4;

  @override
  Future<void> adminSaveProduct(ProductDraft d) async {
    await _wait();
    final id = d.id ?? '${_nextProductId++}';
    final i = _products.indexWhere((p) => p.id == id);
    final product = Product(
      id: id,
      name: d.name.trim(),
      description: d.description.trim(),
      accent: i >= 0 ? _products[i].accent : const Color(0xFFA8321F),
      imageBytes: d.newImageBytes ?? (d.removeImage ? null : d.currentImageBytes),
      variants: [
        for (final size in PackSize.values)
          if (d.prices[size] != null)
            Variant(id: '$id-${size.name}', size: size, price: d.prices[size]!, stock: d.stocks[size]),
      ],
    );
    if (i >= 0) {
      _products[i] = product;
    } else {
      _products.add(product);
    }
  }

  @override
  Future<void> adminDeactivateProduct(String productId) async {
    await _wait();
    _products.removeWhere((p) => p.id == productId);
  }
}
