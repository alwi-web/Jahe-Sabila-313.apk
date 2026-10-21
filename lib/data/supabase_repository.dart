import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'repository.dart';

/// Implementasi data asli di Supabase (lihat supabase/schema.sql).
class SupabaseRepository implements ShopRepository {
  SupabaseClient get _db => Supabase.instance.client;

  String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw AppException('Sesi berakhir, silakan masuk lagi');
    return user.id;
  }

  static const _orderColumns =
      'id, tanggal, total, alamat_kirim, status, kurir, no_resi, detail_pesanan(id, jumlah, harga_satuan, nama_produk, ukuran, varian_produk(produk_id))';

  // ---------------- Akun ----------------

  Future<UserProfile> _profileOf(User user) async {
    final row = await _db.from('profiles').select('nama, no_hp').eq('id', user.id).maybeSingle();
    return UserProfile(
      id: user.id,
      name: (row?['nama'] as String?) ?? '',
      email: user.email ?? '',
      phone: (row?['no_hp'] as String?) ?? '',
    );
  }

  @override
  Future<UserProfile?> currentUser() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return _profileOf(user);
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    final res = await _db.auth.signInWithPassword(email: email, password: password);
    return _profileOf(res.user!);
  }

  @override
  Future<UserProfile?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    // nama dan no_hp disalin ke tabel profiles oleh trigger handle_new_user.
    final res = await _db.auth.signUp(email: email, password: password, data: {'nama': name, 'no_hp': phone});
    if (res.session == null || res.user == null) return null; // perlu konfirmasi email
    return _profileOf(res.user!);
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  @override
  Future<void> sendResetCode(String email) => _db.auth.resetPasswordForEmail(email);

  @override
  Future<void> verifyResetCode(String email, String code) async {
    await _db.auth.verifyOTP(email: email, token: code, type: OtpType.recovery);
  }

  @override
  Future<void> setNewPassword(String newPassword) async {
    await _db.auth.updateUser(UserAttributes(password: newPassword));
    await _db.auth.signOut();
  }

  @override
  Future<bool> changePassword(String email, String oldPassword, String newPassword) async {
    try {
      // Cek password lama dengan masuk ulang.
      await _db.auth.signInWithPassword(email: email, password: oldPassword);
    } on AuthException {
      return false;
    }
    await _db.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }

  @override
  Future<bool> updateProfile(UserProfile profile, {required String previousEmail}) async {
    await _db.from('profiles').update({'nama': profile.name, 'no_hp': profile.phone}).eq('id', _uid);
    if (profile.email.trim().toLowerCase() != previousEmail.trim().toLowerCase()) {
      await _db.auth.updateUser(UserAttributes(email: profile.email));
      return true;
    }
    return false;
  }

  // ---------------- Produk ----------------

  @override
  Future<List<Product>> fetchProducts() async {
    final rows = await _db
        .from('produk')
        .select('id, nama, deskripsi, warna, gambar, varian_produk(id, ukuran, harga, stok)')
        .eq('aktif', true)
        .order('id');
    return rows.map((p) {
      final variants = (p['varian_produk'] as List)
          .map((v) => Variant(
                id: v['id'].toString(),
                size: PackSize.fromLabel(v['ukuran'] as String),
                price: v['harga'] as int,
                stock: v['stok'] as int?,
              ))
          .toList();
      return Product(
        id: p['id'].toString(),
        name: p['nama'] as String,
        description: (p['deskripsi'] as String?) ?? '',
        accent: colorFromHex(p['warna'] as String?),
        imageUrl: p['gambar'] as String?,
        variants: variants,
      );
    }).where((p) => p.variants.isNotEmpty).toList();
  }

  // ---------------- Keranjang ----------------

  @override
  Future<List<CartRow>> fetchCart() async {
    final rows = await _db.from('keranjang').select('varian_id, jumlah').eq('user_id', _uid).order('id');
    return rows.map((r) => (variantId: r['varian_id'].toString(), qty: r['jumlah'] as int)).toList();
  }

  @override
  Future<void> setCartQty(String variantId, int qty) async {
    final vid = int.parse(variantId);
    if (qty <= 0) {
      await _db.from('keranjang').delete().eq('user_id', _uid).eq('varian_id', vid);
    } else {
      await _db
          .from('keranjang')
          .upsert({'user_id': _uid, 'varian_id': vid, 'jumlah': qty}, onConflict: 'user_id,varian_id');
    }
  }

  // ---------------- Alamat ----------------

  @override
  Future<List<Address>> fetchAddresses() async {
    final rows = await _db.from('alamat').select().eq('user_id', _uid).order('id');
    return rows
        .map((r) => Address(
              id: r['id'].toString(),
              label: r['label'] as String,
              recipient: r['nama_penerima'] as String,
              phone: r['no_hp'] as String,
              street: r['alamat_lengkap'] as String,
              city: r['kota'] as String,
              postalCode: r['kode_pos'] as String,
              note: (r['catatan'] as String?) ?? '',
              isMain: r['is_utama'] as bool,
            ))
        .toList();
  }

  @override
  Future<String> saveAddress(Address a) async {
    final data = {
      'label': a.label,
      'nama_penerima': a.recipient,
      'no_hp': a.phone,
      'alamat_lengkap': a.street,
      'kota': a.city,
      'kode_pos': a.postalCode,
      'catatan': a.note,
    };
    if (a.isNew) {
      final row = await _db.from('alamat').insert({...data, 'user_id': _uid}).select('id').single();
      return row['id'].toString();
    }
    await _db.from('alamat').update(data).eq('id', int.parse(a.id));
    return a.id;
  }

  @override
  Future<void> setMainAddress(String id) async {
    await _db.rpc('set_alamat_utama', params: {'p_id': int.parse(id)});
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _db.from('alamat').delete().eq('id', int.parse(id));
  }

  // ---------------- Pesanan ----------------

  Order _orderFromRow(Map<String, dynamic> r, {String buyerName = '', String buyerPhone = ''}) {
    final lines = (r['detail_pesanan'] as List)
        .map((d) => OrderLine(
              productName: d['nama_produk'] as String,
              productId: (d['varian_produk'] as Map?)?['produk_id']?.toString(),
              size: PackSize.fromLabel(d['ukuran'] as String),
              qty: d['jumlah'] as int,
              unitPrice: d['harga_satuan'] as int,
            ))
        .toList();
    return Order(
      id: r['id'].toString(),
      date: DateTime.parse(r['tanggal'] as String).toLocal(),
      total: r['total'] as int,
      addressText: r['alamat_kirim'] as String,
      status: OrderStatus.fromCode(r['status'] as String),
      courier: (r['kurir'] as String?) ?? '',
      trackingNumber: (r['no_resi'] as String?) ?? '',
      lines: lines,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
    );
  }

  @override
  Future<List<Order>> fetchOrders() async {
    final rows = await _db.from('pesanan').select(_orderColumns).eq('user_id', _uid).order('id', ascending: false);
    return rows.map(_orderFromRow).toList();
  }

  @override
  Future<Order> placeOrder(String addressId) async {
    final id = await _db.rpc('buat_pesanan', params: {'p_alamat_id': int.parse(addressId)});
    final row = await _db.from('pesanan').select(_orderColumns).eq('id', id as int).single();
    return _orderFromRow(row);
  }

  // ---------------- Admin ----------------

  @override
  Future<String> fetchRole() async {
    final row = await _db.from('profiles').select('role').eq('id', _uid).maybeSingle();
    return (row?['role'] as String?) ?? 'pembeli';
  }

  @override
  Future<List<Order>> adminFetchOrders() async {
    final rows = await _db.from('pesanan').select('user_id, $_orderColumns').order('id', ascending: false);
    final ids = rows.map((r) => r['user_id'] as String).toSet().toList();
    final buyers = <String, Map<String, dynamic>>{};
    if (ids.isNotEmpty) {
      final profs = await _db.from('profiles').select('id, nama, no_hp').inFilter('id', ids);
      for (final p in profs) {
        buyers[p['id'] as String] = p;
      }
    }
    return rows.map((r) {
      final b = buyers[r['user_id']];
      return _orderFromRow(
        r,
        buyerName: (b?['nama'] as String?) ?? '',
        buyerPhone: (b?['no_hp'] as String?) ?? '',
      );
    }).toList();
  }

  @override
  Future<void> adminSetOrderStatus(String orderId, OrderStatus status) async {
    // Fungsi database ini juga mengembalikan stok kalau pesanan dibatalkan.
    await _db.rpc('ubah_status_pesanan', params: {'p_id': int.parse(orderId), 'p_status': status.code});
  }

  @override
  Future<void> adminSetShipping(String orderId, String courier, String trackingNumber) async {
    await _db
        .from('pesanan')
        .update({'kurir': courier.isEmpty ? null : courier, 'no_resi': trackingNumber.isEmpty ? null : trackingNumber})
        .eq('id', int.parse(orderId));
  }

  @override
  Future<void> adminSaveProduct(ProductDraft d) async {
    final data = {'nama': d.name.trim(), 'deskripsi': d.description.trim()};
    final int productId;
    if (d.id == null) {
      final row = await _db.from('produk').insert(data).select('id').single();
      productId = row['id'] as int;
    } else {
      productId = int.parse(d.id!);
      await _db.from('produk').update(data).eq('id', productId);
    }
    // Foto produk disimpan di Supabase Storage (bucket "produk"), URL-nya di produk.gambar.
    String? imageUrl = d.removeImage ? null : d.imageUrl;
    if (d.newImageBytes != null) {
      final path = '$productId/${DateTime.now().millisecondsSinceEpoch}.${d.newImageExt}';
      await _db.storage.from('produk').uploadBinary(
            path,
            d.newImageBytes!,
            fileOptions: FileOptions(contentType: d.newImageExt == 'png' ? 'image/png' : 'image/jpeg', upsert: true),
          );
      imageUrl = _db.storage.from('produk').getPublicUrl(path);
    }
    await _db.from('produk').update({'gambar': imageUrl}).eq('id', productId);

    final variants = [
      for (final size in PackSize.values)
        if (d.prices[size] != null)
          {'produk_id': productId, 'ukuran': size.label, 'harga': d.prices[size], 'stok': d.stocks[size]},
    ];
    await _db.from('varian_produk').upsert(variants, onConflict: 'produk_id,ukuran');
  }

  @override
  Future<void> adminDeactivateProduct(String productId) async {
    await _db.from('produk').update({'aktif': false}).eq('id', int.parse(productId));
  }
}
