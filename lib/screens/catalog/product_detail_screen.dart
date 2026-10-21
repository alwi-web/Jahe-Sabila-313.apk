import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Variant _variant = widget.product.variants.first;
  int _qty = 1;

  void _addToCart() {
    context.read<AppState>().addToCart(widget.product, _variant, _qty);
    final added = '${_variant.size.label} x $_qty';
    setState(() => _qty = 1);
    // Tetap di halaman ini supaya pengguna bisa lanjut memilih barang.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Masuk ke keranjang · $added'),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: const Color(0xFFF7C9BE),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen(pushed: true)),
          ),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail produk'), actions: const [CartIconButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          LayoutBuilder(
            builder: (context, c) => ProductPhoto(
              product: p,
              width: c.maxWidth,
              height: 248,
              packWidth: 140,
              showLabel: true,
              radius: 16,
            ),
          ),
          const SizedBox(height: 20),
          Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 6),
          Text(rupiah(_variant.price),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brand)),
          const SizedBox(height: 6),
          Text(p.description, style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 20),
          const Text('Ukuran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            for (final v in p.variants) ...[
              Expanded(
                child: SelectPill(
                  label: v.soldOut ? '${v.size.label} (habis)' : v.size.label,
                  selected: v.id == _variant.id,
                  onTap: () => setState(() => _variant = v),
                ),
              ),
              if (v != p.variants.last) const SizedBox(width: 10),
            ],
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Text('Jumlah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            QtyStepper(
              qty: _qty,
              onDecrease: () => setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
              onIncrease: () => setState(() => _qty++),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton.icon(
          onPressed: _variant.soldOut ? null : _addToCart,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Masukkan ke keranjang'),
        ),
      ]),
    );
  }
}
