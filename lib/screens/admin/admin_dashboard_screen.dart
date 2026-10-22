import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../home/router.dart';
import 'admin_order_detail_screen.dart';
import 'admin_shell.dart';
import 'store_settings_screen.dart';

/// Batas stok yang dianggap menipis.
const lowStockLimit = 5;

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) => runGuarded(context, () async {
        final s = context.read<AppState>();
        await s.loadAdminOrders();
        await s.loadProducts();
      });

  Future<void> _logout(BuildContext context) async {
    final ok = await runGuarded(context, context.read<AppState>().signOut);
    if (!ok || !context.mounted) return;
    // Setelah keluar kembali ke Beranda sebagai tamu.
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => homeFor(context.read<AppState>())), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final now = DateTime.now();
    final monthSales = state.adminOrders
        .where((o) => o.status != OrderStatus.cancelled && o.date.year == now.year && o.date.month == now.month)
        .fold(0, (sum, o) => sum + o.total);
    var lowStock = 0;
    for (final p in state.products) {
      for (final v in p.variants) {
        if (v.stock != null && v.stock! <= lowStockLimit) lowStock++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Beranda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Pengaturan toko',
            style: IconButton.styleFrom(backgroundColor: AppColors.cream),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreSettingsScreen())),
            icon: const Icon(Icons.settings_outlined, color: AppColors.brand),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Keluar',
              style: IconButton.styleFrom(backgroundColor: AppColors.cream),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.brand),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Text('Ringkasan toko', style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _StatCard(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Menunggu bayar',
                  value: '${state.countByStatus(OrderStatus.waitingPayment)}',
                  onTap: () => state.openAdminOrders(OrderStatus.waitingPayment),
                ),
                _StatCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Perlu dikirim',
                  value: '${state.countByStatus(OrderStatus.processing)}',
                  onTap: () => state.openAdminOrders(OrderStatus.processing),
                ),
                _StatCard(
                    icon: Icons.payments_outlined, label: 'Penjualan bulan ini', value: rupiah(monthSales), small: true),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stok menipis',
                  value: '$lowStock varian',
                  alert: lowStock > 0,
                  onTap: () => state.setAdminTab(2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(
                child: Text('Pesanan terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              TextButton(onPressed: () => state.openAdminOrders(null), child: const Text('Lihat semua')),
            ]),
            const SizedBox(height: 4),
            if (state.loadingAdminOrders && state.adminOrders.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (state.adminOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Belum ada pesanan.', style: TextStyle(color: AppColors.muted)),
              )
            else
              for (final o in state.adminOrders.take(5)) ...[
                AdminOrderTile(
                  order: o,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: o)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.small = false,
    this.alert = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool small;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppShadow.card),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: alert ? const Color(0xFFE3B8AE) : AppColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: alert ? const Color(0xFFF7E3DE) : AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: alert ? AppColors.brand : AppColors.brown),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: TextStyle(
                      fontSize: small ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: alert ? AppColors.brand : AppColors.ink,
                    )),
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
            ]),
          ),
        ),
      ),
    );
  }
}
