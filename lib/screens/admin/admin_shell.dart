import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_report_screen.dart';

/// Kerangka admin: Beranda, Pesanan, Produk, Laporan.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final waiting = state.countByStatus(OrderStatus.waitingPayment);
    return Scaffold(
      body: IndexedStack(
        index: state.adminTab,
        children: const [AdminDashboardScreen(), AdminOrdersScreen(), AdminProductsScreen(), AdminReportScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.adminTab,
        onDestinationSelected: state.setAdminTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.cream,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.brand),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: waiting > 0,
              label: Text('$waiting'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: waiting > 0,
              label: Text('$waiting'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.receipt_long, color: AppColors.brand),
            ),
            label: 'Pesanan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.brand),
            label: 'Produk',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.brand),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkas satu pesanan, dipakai di Beranda dan daftar Pesanan.
class AdminOrderTile extends StatelessWidget {
  const AdminOrderTile({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pesanan #${order.number}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(
                    '${order.buyerName.isEmpty ? 'Pembeli' : order.buyerName} · ${shortDate(order.date)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ]),
              ),
              StatusPill(order.status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('${order.itemCount} barang', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ),
              Text(rupiah(order.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: status.background, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: TextStyle(color: status.foreground, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
