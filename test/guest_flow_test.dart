import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sabila313/data/app_state.dart';
import 'package:sabila313/data/memory_repository.dart';
import 'package:sabila313/screens/home/home_shell.dart';

/// Tamu membuka aplikasi: Beranda tampil tanpa login, Produk bisa dilihat,
/// dan menambah ke keranjang mengarahkan ke halaman Masuk.
void main() {
  testWidgets('tamu: beranda, produk, lalu diminta masuk saat menambah ke keranjang', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final state = AppState(MemoryRepository(latency: Duration.zero));
    await tester.runAsync(state.bootstrap);
    expect(state.loggedIn, isFalse);
    expect(state.products, isNotEmpty);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Kenapa memilih Sabila 313?'), findsOneWidget);
    expect(find.text('Bersertifikat halal'), findsOneWidget);

    // Tab Keranjang untuk tamu -> halaman Masuk.
    await tester.tap(find.text('Keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk untuk mulai berbelanja'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Lihat produk -> tab Produk -> detail -> tambah ke keranjang -> halaman Masuk.
    await tester.tap(find.text('Lihat produk'));
    await tester.pumpAndSettle();
    expect(state.tab, AppState.tabProducts);
    await tester.tap(find.text(state.products.first.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masukkan ke keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk untuk mulai berbelanja'), findsOneWidget);
    expect(state.cartCount, 0);
  });
}
