import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = state.products;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Jahe Merah Sabila 313',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brown)),
        actions: const [CartIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => runGuarded(context, state.loadProducts),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const Text('Produk kami', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Pilih varian jahe merah favoritmu', style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 16),
            if (state.loadingProducts && products.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  const Text('Produk belum bisa dimuat.', style: TextStyle(color: AppColors.muted)),
                  TextButton(onPressed: () => runGuarded(context, state.loadProducts), child: const Text('Coba lagi')),
                ]),
              )
            else
              for (final p in products) ...[
                _ProductCard(product: p),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  void _open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _open(context),
      child: AppCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProductThumb(size: 96, product: product),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 4),
              Text(product.description, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 4),
              Text(product.variants.map((v) => v.size.label).join(' · '),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brown)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Mulai', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text(rupiah(product.startingPrice),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand)),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _open(context),
                  child: const Text('Pilih'),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
