import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:sabila313/data/app_state.dart';
import 'package:sabila313/data/memory_repository.dart';
import 'package:sabila313/data/models.dart';
import 'package:sabila313/utils/format.dart';

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
}
