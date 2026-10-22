import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

import 'package:sabila313/data/app_state.dart';
import 'package:sabila313/data/memory_repository.dart';
import 'package:sabila313/data/models.dart';
import 'package:sabila313/utils/errors.dart';
import 'package:sabila313/utils/format.dart';
import 'package:sabila313/utils/whatsapp.dart';

/// Menguji logika aplikasi memakai MemoryRepository (tanpa Supabase).
Future<AppState> loggedInState() async {
  final s = AppState(MemoryRepository(latency: Duration.zero));
  await s.signUp(name: 'Alwi', email: 'alwi@contoh.com', phone: '0812', password: 'rahasia123');
  return s;
}

void main() {
  test('format rupiah', () {
    expect(rupiah(105000), 'Rp 105.000');
    expect(rupiah(28000), 'Rp 28.000');
    expect(rupiah(1250000), 'Rp 1.250.000');
  });

  test('produk dan harga termuat', () async {
    final s = await loggedInState();
    expect(s.products.length, 3);
    expect(s.products[0].name, 'Jahe Merah dengan Gula Pasir');
    expect(s.products[1].variantOf(PackSize.kg1)!.price, 111000);
    expect(s.products[2].startingPrice, 25000);
  });

  test('keranjang: tambah, kurangi sampai hapus, dan total', () async {
    final s = await loggedInState();
    final gulaPasir = s.products[0];
    final tanpaGula = s.products[2];

    await s.addToCart(gulaPasir, gulaPasir.variantOf(PackSize.g250)!, 2);
    await s.addToCart(tanpaGula, tanpaGula.variantOf(PackSize.g500)!, 1);
    expect(s.cartCount, 3);
    expect(s.cartTotal, 2 * 28000 + 48000);

    final key = s.cart.first.key;
    await s.changeQty(key, -1);
    expect(s.cart.first.qty, 1);
    await s.changeQty(key, -1); // jumlah 1 dikurangi = terhapus
    expect(s.cart.length, 1);
    expect(s.cartTotal, 48000);

    // Isi keranjang tersimpan di repository (dimuat ulang tetap sama).
    await s.loadCart();
    expect(s.cartTotal, 48000);
  });

  test('alamat pertama jadi utama, checkout menyimpan pesanan', () async {
    final s = await loggedInState();
    final a = s.newAddressDraft()
      ..street = 'Jl. Mawar 5'
      ..city = 'Jakarta'
      ..postalCode = '12345';
    await s.saveAddress(a, makeMain: false);
    expect(s.mainAddress?.street, 'Jl. Mawar 5');

    final kantor = s.newAddressDraft()
      ..label = 'Kantor'
      ..street = 'Jl. Kenanga 9'
      ..city = 'Depok'
      ..postalCode = '16424';
    await s.saveAddress(kantor, makeMain: true);
    expect(s.mainAddress?.label, 'Kantor');

    final gulaMerah = s.products[1];
    await s.addToCart(gulaMerah, gulaMerah.variantOf(PackSize.kg1)!, 2);
    final order = await s.placeOrder();
    expect(order.total, 222000);
    expect(order.status, OrderStatus.waitingPayment);
    expect(order.addressText, contains('Kenanga'));
    expect(s.cartEmpty, isTrue);
    expect(s.orders.first.number, '001');
  });

  test('ubah password: password lama salah ditolak', () async {
    final s = await loggedInState();
    expect(await s.changePassword('salah', 'barubaru123'), isFalse);
    expect(await s.changePassword('rahasia123', 'barubaru123'), isTrue);
  });

  test('akun admin: peran, semua pesanan, ubah status, produk', () async {
    final repo = MemoryRepository(latency: Duration.zero);
    // Pembeli memesan dulu.
    final buyer = AppState(repo);
    await buyer.signUp(name: 'Budi', email: 'budi@contoh.com', phone: '0813', password: 'rahasia123');
    expect(buyer.isAdmin, isFalse);
    final addr = buyer.newAddressDraft()
      ..street = 'Jl. Melati 1'
      ..city = 'Bogor'
      ..postalCode = '16100';
    await buyer.saveAddress(addr, makeMain: true);
    final p = buyer.products[0];
    await buyer.addToCart(p, p.variantOf(PackSize.g250)!, 3);
    await buyer.placeOrder();
    await buyer.signOut();

    // Admin melihat dan mengubahnya.
    final admin = AppState(repo);
    await admin.signIn('admin@sabila313.com', 'admin12345');
    expect(admin.isAdmin, isTrue);
    expect(admin.adminOrders.length, 1);
    expect(admin.adminOrders.first.buyerName, 'Budi');
    expect(admin.countByStatus(OrderStatus.waitingPayment), 1);
    await admin.setOrderStatus(admin.adminOrders.first, OrderStatus.processing);
    expect(admin.countByStatus(OrderStatus.processing), 1);
    await admin.setShipping(admin.adminOrders.first, 'J&T', 'JT0012345');
    expect((await repo.fetchOrders()).first.trackingNumber, 'JT0012345');
    expect(admin.adminOrders.first.courier, 'J&T');

    await admin.saveProduct(ProductDraft(
      name: 'Jahe Merah dengan Madu',
      prices: {PackSize.g250: 32000, PackSize.g500: 60000, PackSize.kg1: 115000},
      stocks: {PackSize.g250: 10, PackSize.g500: null, PackSize.kg1: 2},
    ));
    expect(admin.products.length, 4);
    expect(admin.products.last.variantOf(PackSize.kg1)!.stock, 2);
    expect(admin.products.last.hasPhoto, isFalse);

    // Tambah foto ke produk itu, lalu hapus lagi.
    final withPhoto = ProductDraft.fromProduct(admin.products.last)
      ..newImageBytes = Uint8List.fromList([1, 2, 3]);
    await admin.saveProduct(withPhoto);
    expect(admin.products.last.hasPhoto, isTrue);
    final noPhoto = ProductDraft.fromProduct(admin.products.last)..removeImage = true;
    await admin.saveProduct(noPhoto);
    expect(admin.products.last.hasPhoto, isFalse);
    await admin.deactivateProduct(admin.products.last.id);
    expect(admin.products.length, 3);
  });

  test('pesan WhatsApp pembeli dan admin berisi nama, no. HP, alamat, jumlah, dan status', () {
    final order = Order(
      id: '7',
      date: DateTime(2026, 10, 21),
      lines: const [
        OrderLine(productName: 'Jahe Merah Tanpa Gula', productId: '3', size: PackSize.g500, qty: 2, unitPrice: 48000),
      ],
      addressText: 'Alwi (0812)\nJl. Melati 1, Bogor 16111',
      total: 96000,
      buyerName: 'Alwi',
      buyerPhone: '0812',
    );
    final buyer = UserProfile(id: 'u1', name: 'Alwi', email: 'alwi@contoh.com', phone: '0812');

    final pesan = buildOrderMessage(order, buyer);
    expect(pesan, contains('No. pesanan: #007'));
    expect(pesan, contains('Jahe Merah Tanpa Gula'));
    expect(pesan, contains('x2 = Rp 96.000'));
    expect(pesan, contains('Nama: Alwi'));
    expect(pesan, contains('No. HP: 0812'));
    expect(pesan, contains('Jl. Melati 1, Bogor 16111'));

    order.status = OrderStatus.processing;
    final admin = buildAdminOrderMessage(order);
    expect(admin, startsWith('Halo Alwi, berikut pesanan Anda'));
    expect(admin, contains('x2 = Rp 96.000'));
    expect(admin, contains('No. HP: 0812'));
    expect(admin, contains('Jl. Melati 1, Bogor 16111'));
    expect(admin, endsWith('Status pesanan: Diproses'));
    expect(admin, isNot(contains('No. resi')));

    order
      ..courier = 'JNE'
      ..trackingNumber = 'JP1234567890';
    final dikirim = buildAdminOrderMessage(order);
    expect(dikirim, contains('Kurir: JNE'));
    expect(dikirim, contains('No. resi: JP1234567890'));

  });

  test('pengaturan toko: nomor WhatsApp dinormalisasi dan disimpan', () async {
    expect(normalizeWhatsAppNumber('0812-3456-7890'), '6281234567890');
    expect(normalizeWhatsAppNumber('+62 812 3456 7890'), '6281234567890');
    expect(normalizeWhatsAppNumber('81234567890'), '6281234567890');

    final repo = MemoryRepository(latency: Duration.zero);
    final admin = AppState(repo);
    await admin.signIn('admin@sabila313.com', 'admin12345');
    await admin.saveStoreWhatsApp('0899 1111 2222');
    expect(admin.storeWhatsApp, '6289911112222');

    // Pembeli yang masuk setelahnya memakai nomor baru.
    final buyer = AppState(repo);
    await buyer.signUp(name: 'Sari', email: 'sari@contoh.com', phone: '0815', password: 'rahasia123');
    expect(buyer.storeWhatsApp, '6289911112222');
  });

  test('notif pembeli: pesanan yang diubah admin ditandai sampai riwayat dibuka', () async {
    final repo = MemoryRepository(latency: Duration.zero);
    final buyer = AppState(repo);
    await buyer.signUp(name: 'Rina', email: 'rina@contoh.com', phone: '0817', password: 'rahasia123');
    final addr = buyer.newAddressDraft()
      ..street = 'Jl. Mawar 2'
      ..city = 'Depok'
      ..postalCode = '16400';
    await buyer.saveAddress(addr, makeMain: true);
    final p = buyer.products[1];
    await buyer.addToCart(p, p.variantOf(PackSize.g500)!, 1);
    final order = await buyer.placeOrder();
    expect(order.payBefore, order.date.add(const Duration(hours: 3)));
    expect(buyer.unreadOrderUpdates, 0);

    final admin = AppState(repo);
    await admin.signIn('admin@sabila313.com', 'admin12345');
    await admin.setOrderStatus(admin.adminOrders.first, OrderStatus.processing);

    await buyer.loadOrders();
    expect(buyer.unreadOrderUpdates, 1);
    await buyer.markOrdersRead();
    expect(buyer.unreadOrderUpdates, 0);

    await admin.setShipping(admin.adminOrders.first, 'JNE', 'JP777');
    await buyer.loadOrders();
    expect(buyer.unreadOrderUpdates, 1);
  });

  test('batas bayar 3 jam', () {
    final dibuat = DateTime(2026, 10, 21, 9, 0);
    final o = Order(id: '1', date: dibuat, lines: const [], addressText: '', total: 0);
    expect(o.payBefore, DateTime(2026, 10, 21, 12, 0));
    expect(dateTime(o.payBefore), '21 Okt 2026, 12.00');
  });

  test('foto profil: ganti, tetap ada setelah ubah profil, lalu hapus', () async {
    final s = await loggedInState();
    expect(s.profile.hasPhoto, isFalse);
    await s.changeProfilePhoto(Uint8List.fromList([1, 2, 3]), 'jpg');
    expect(s.profile.hasPhoto, isTrue);
    await s.updateProfile(name: 'Alwi S', email: s.profile.email, phone: '0812');
    expect(s.profile.hasPhoto, isTrue);
    await s.removeProfilePhoto();
    expect(s.profile.hasPhoto, isFalse);
  });

  test('pesan error unggah foto (Storage) jelas, bukan pesan umum', () {
    expect(friendlyError(const StorageException('Bucket not found', statusCode: '404')), contains('belum disiapkan'));
    expect(friendlyError(const StorageException('new row violates row-level security policy', statusCode: '403')),
        contains('Tidak diizinkan'));
    expect(friendlyError(const StorageException('Something else', statusCode: '500')), 'Gagal mengunggah foto: Something else');
  });
}
