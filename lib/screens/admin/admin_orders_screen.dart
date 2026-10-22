import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_order_detail_screen.dart';
import 'admin_shell.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filter = state.adminOrderFilter;
    final q = _search.text.trim().toLowerCase();
    final orders = state.adminOrders.where((o) {
      if (filter != null && o.status != filter) return false;
      if (q.isEmpty) return true;
      return o.number.contains(q) || o.id.contains(q) || o.buyerName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cari no. pesanan atau nama',
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            children: [
              _Chip(label: 'Semua', selected: filter == null, onTap: () => state.setAdminOrderFilter(null)),
              for (final s in OrderStatus.values)
                _Chip(label: s.label, selected: filter == s, onTap: () => state.setAdminOrderFilter(s)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => runGuarded(context, state.loadAdminOrders),
            child: orders.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(child: Text('Tidak ada pesanan yang cocok.', style: TextStyle(color: AppColors.muted))),
                    ),
                  ])
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => AdminOrderTile(
                      order: orders[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(order: orders[i])),
                      ),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

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
