import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sabila313/data/app_state.dart';
import 'package:sabila313/data/memory_repository.dart';
import 'package:sabila313/screens/home/home_shell.dart';
import 'package:sabila313/screens/home/landing_screen.dart';
import 'package:sabila313/widgets/common.dart';

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
    // Carousel Pilihan varian: digeser ke kiri lalu kartu di tengah membuka detail produk.
    final page = find.descendant(of: find.byType(LandingScreen), matching: find.byType(Scrollable)).first;
    await tester.dragUntilVisible(find.byType(PageView), page, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan ke keranjang'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(page, const Offset(0, 3000));
    await tester.pumpAndSettle();

    // Tab Keranjang untuk tamu -> halaman Masuk.
    await tester.tap(find.text('Keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk untuk mulai berbelanja'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Banner -> tab Produk -> detail -> tambah ke keranjang -> halaman Masuk.
    // Banner sambutan membuka tab Produk.
    await tester.tap(find.text('Jahe Merah Asli dari Petani Lokal'));
    await tester.pumpAndSettle();
    expect(state.tab, AppState.tabProducts);
    await tester.tap(find.text(state.products.first.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masukkan ke keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk untuk mulai berbelanja'), findsOneWidget);
    expect(state.cartCount, 0);
  });

  testWidgets('mengetuk tab Beranda saat sudah di Beranda menggulir ke atas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final state = AppState(MemoryRepository(latency: Duration.zero));
    await tester.runAsync(state.bootstrap);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state,
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();

    final list = find.descendant(of: find.byType(LandingScreen), matching: find.byType(Scrollable)).first;
    await tester.drag(list, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(list).position.pixels, greaterThan(0));

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(list).position.pixels, 0);
  });

  testWidgets('password langsung tampil sebagai titik saat diketik', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PasswordField(label: 'Password', controller: controller)),
    ));
    String shown() => tester.allRenderObjects.whereType<RenderEditable>().first.text!.toPlainText();
    await tester.enterText(find.byType(TextField), 'rahasia1');
    await tester.pump();
    expect(controller.text, 'rahasia1');
    expect(shown(), '\u2022' * 8);

    await tester.tap(find.byTooltip('Tampilkan password'));
    await tester.pump();
    expect(shown(), 'rahasia1');

    controller.clear();
    await tester.pump();
    expect(shown(), '');
  });
}
