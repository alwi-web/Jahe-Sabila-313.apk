import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

/// Dipakai sebagai tab "Keranjang" dan sebagai halaman yang dibuka dari
/// ikon keranjang ([pushed] = true, menampilkan tombol kembali).
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.pushed = false});

  final bool pushed;

  void _goShopping(BuildContext context) {
    context.read<AppState>().setTab(0);
    if (pushed) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.cart;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: pushed, title: const Text('Keranjang')),
      body: items.isEmpty
          ? _EmptyCart(onShop: () => _goShopping(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              children: [
                for (final it in items) ...[
                  _CartRow(item: it),
                  const SizedBox(height: 12),
                ],
                Center(
                  child: TextButton(onPressed: () => _goShopping(context), child: const Text('+ Tambah barang lain')),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : BottomActions(children: [
              Row(children: [
                Expanded(
                  child: Text('Subtotal (${state.cartCount} barang)',
                      style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ),
                Text(rupiah(state.cartTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                child: const Text('Checkout'),
              ),
            ]),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return AppCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProductThumb(size: 72, product: item.product),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 2),
                  Text(item.size.label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ]),
              ),
              IconButton(
                tooltip: 'Hapus dari keranjang',
                visualDensity: VisualDensity.compact,
                onPressed: () => state.removeFromCart(item.key),
                icon: const Icon(Icons.delete_outline, color: AppColors.muted),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text(rupiah(item.lineTotal),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand)),
              ),
              QtyStepper(
                qty: item.qty,
                // Jumlah 1 lalu dikurangi = barang dihapus.
                decreaseTooltip: item.qty == 1 ? 'Hapus ${item.product.name} ${item.size.label}' : 'Kurangi',
                onDecrease: () => state.changeQty(item.key, -1),
                onIncrease: () => state.changeQty(item.key, 1),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_cart_outlined, size: 36, color: AppColors.brown),
          ),
          const SizedBox(height: 16),
          const Text('Keranjang masih kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Pilih varian jahe merah dulu, lalu masukkan ke keranjang.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(160, 44)),
            onPressed: onShop,
            child: const Text('Mulai belanja'),
          ),
        ]),
      ),
    );
  }
}
