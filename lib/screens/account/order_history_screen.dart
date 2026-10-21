import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/common.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  OrderStatus? _filter; // null = Semua

  /// Pesanan yang diperbarui admin sejak terakhir dilihat; ditandai "Diperbarui" selama layar ini terbuka.
  final _fresh = <String>{};

  @override
  void initState() {
    super.initState();
    // Muat ulang supaya status yang diubah admin langsung terlihat, lalu tandai sudah dibaca.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final state = context.read<AppState>();
      await runGuarded(context, state.loadOrders);
      if (!mounted) return;
      setState(() => _fresh.addAll(state.orders.where((o) => o.hasUnreadUpdate).map((o) => o.id)));
      await runGuarded(context, state.markOrdersRead);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final orders = state.orders.where((o) => _filter == null || o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat pesanan')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            children: [
              _FilterChip(label: 'Semua', selected: _filter == null, onTap: () => setState(() => _filter = null)),
              for (final s in OrderStatus.values)
                _FilterChip(label: s.label, selected: _filter == s, onTap: () => setState(() => _filter = s)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            // Tarik ke bawah untuk melihat status terbaru dari admin.
            onRefresh: () => runGuarded(context, state.loadOrders),
            child: orders.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(
                        child: state.loadingOrders
                            ? const CircularProgressIndicator()
                            : Text(
                                state.orders.isEmpty ? 'Belum ada pesanan.' : 'Belum ada pesanan dengan status ini.',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                      ),
                    ),
                  ])
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _OrderCard(order: orders[i], fresh: _fresh.contains(orders[i].id)),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.brand,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.brand : AppColors.field),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.fresh = false});

  final Order order;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Pesanan #${order.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                if (fresh) ...[
                  const SizedBox(width: 8),
                  const Badge(label: Text('Diperbarui'), backgroundColor: AppColors.brand),
                ],
              ]),
              Text(shortDate(order.date), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
          ),
          StatusBadge(order.status),
        ]),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        for (final l in order.lines)
          Text('${l.productName}, ${l.size.label} x ${l.qty}', style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text('Total (${order.itemCount} barang)',
                style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          ),
          Text(rupiah(order.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        if (order.hasTracking) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText('${order.courier} · Resi ${order.trackingNumber}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ],
        if (order.status == OrderStatus.waitingPayment) ...[
          const SizedBox(height: 12),
          Text('Bayar sebelum ${dateTime(order.payBefore)}. Lewat dari itu pesanan dibatalkan otomatis.',
              style: const TextStyle(fontSize: 13, color: AppColors.brand, height: 1.4)),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp, minimumSize: const Size.fromHeight(44)),
            onPressed: () => openWhatsApp(state.storeWhatsApp, buildOrderMessage(order, state.profile)),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Konfirmasi via WhatsApp', style: TextStyle(fontSize: 14)),
          ),
        ],
        if (order.status == OrderStatus.done) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            onPressed: () async {
              final missing = await state.reorder(order);
              if (!context.mounted) return;
              state.setTab(1);
              Navigator.of(context).popUntil((r) => r.isFirst);
              if (missing > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$missing barang sudah tidak tersedia dan tidak dimasukkan')),
                );
              }
            },
            child: const Text('Pesan lagi', style: TextStyle(fontSize: 14)),
          ),
        ],
      ]),
    );
  }
}
