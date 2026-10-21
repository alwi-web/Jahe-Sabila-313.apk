import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'admin_dashboard_screen.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  Future<void> _openForm(BuildContext context, ProductDraft draft) async {
    final msg = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => AdminProductFormScreen(draft: draft)),
    );
    if (msg != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Produk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(44, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => _openForm(context, ProductDraft()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => runGuarded(context, state.loadProducts),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text('${state.products.length} produk · harga dan stok per ukuran',
                style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 12),
            for (final p in state.products) ...[
              _ProductCard(product: p, onEdit: () => _openForm(context, ProductDraft.fromProduct(p))),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onEdit});

  final Product product;
  final VoidCallback onEdit;

  bool _low(Variant v) => v.stock != null && v.stock! <= lowStockLimit;

  @override
  Widget build(BuildContext context) {
    final anyLow = product.variants.any(_low);
    return AppCard(
      child: Column(children: [
        Row(children: [
          ProductThumb(size: 56, product: product),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
              if (anyLow)
                const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.brand),
                  SizedBox(width: 4),
                  Text('Stok menipis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brand)),
                ]),
            ]),
          ),
          IconButton(
            tooltip: 'Ubah ${product.name}',
            style: IconButton.styleFrom(backgroundColor: AppColors.cream),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ]),
        const SizedBox(height: 10),
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.4), 2: FlexColumnWidth(1.2)},
          children: [
            const TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              children: [
                _Cell('Ukuran', header: true),
                _Cell('Harga', header: true, right: true),
                _Cell('Stok', header: true, right: true),
              ],
            ),
            for (final v in product.variants)
              TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                children: [
                  _Cell(v.size.label),
                  _Cell(rupiah(v.price), right: true),
                  _Cell(
                    v.stock == null ? '—' : (_low(v) ? '${v.stock} (menipis)' : '${v.stock}'),
                    right: true,
                    alert: _low(v),
                  ),
                ],
              ),
          ],
        ),
      ]),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false, this.right = false, this.alert = false});

  final String text;
  final bool header;
  final bool right;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: header ? 12 : 14,
          color: header ? AppColors.muted : (alert ? AppColors.brand : AppColors.ink),
          fontWeight: header ? FontWeight.w600 : (alert ? FontWeight.w700 : FontWeight.w400),
        ),
      ),
    );
  }
}
