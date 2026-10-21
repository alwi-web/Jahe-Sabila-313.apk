import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'report_export.dart';

enum _Period { thisMonth, lastMonth, all }

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  _Period _period = _Period.thisMonth;
  bool _exporting = false;

  static const _labels = {
    _Period.thisMonth: 'Bulan ini',
    _Period.lastMonth: 'Bulan lalu',
    _Period.all: 'Semua waktu',
  };

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.thisMonth:
        return d.year == now.year && d.month == now.month;
      case _Period.lastMonth:
        final prev = DateTime(now.year, now.month - 1);
        return d.year == prev.year && d.month == prev.month;
      case _Period.all:
        return true;
    }
  }

  ReportData _build(List<Order> all) {
    final inPeriod = all.where((o) => _inPeriod(o.date)).toList();
    final done = inPeriod.where((o) => o.status == OrderStatus.done).toList();
    final perProduct = <String, ({int qty, int revenue})>{};
    for (final o in done) {
      for (final l in o.lines) {
        final cur = perProduct[l.productName] ?? (qty: 0, revenue: 0);
        perProduct[l.productName] = (qty: cur.qty + l.qty, revenue: cur.revenue + l.total);
      }
    }
    final rows = perProduct.entries
        .map((e) => ReportRow(product: e.key, qty: e.value.qty, revenue: e.value.revenue))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final label = switch (_period) {
      _Period.thisMonth => '${months[now.month - 1]} ${now.year}',
      _Period.lastMonth => '${months[prev.month - 1]} ${prev.year}',
      _Period.all => 'Semua waktu',
    };
    return ReportData(
      periodLabel: label,
      revenue: done.fold(0, (s, o) => s + o.total),
      doneCount: done.length,
      cancelledCount: inPeriod.where((o) => o.status == OrderStatus.cancelled).length,
      rows: rows,
    );
  }

  Future<void> _export(Future<void> Function(ReportData) fn, ReportData data) async {
    setState(() => _exporting = true);
    await runGuarded(context, () => fn(data));
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final r = _build(state.adminOrders);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Laporan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => runGuarded(context, state.loadAdminOrders),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in _Period.values)
                ChoiceChip(
                  label: Text(_labels[p]!),
                  selected: _period == p,
                  onSelected: (_) => setState(() => _period = p),
                  showCheckmark: false,
                  selectedColor: AppColors.brand,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: _period == p ? AppColors.brand : AppColors.field),
                  labelStyle: TextStyle(
                    color: _period == p ? Colors.white : AppColors.ink,
                    fontWeight: _period == p ? FontWeight.w700 : FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pendapatan (${r.periodLabel})', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(rupiah(r.revenue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Text('Dari pesanan berstatus Selesai', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _MiniStat(label: 'Pesanan selesai', value: '${r.doneCount}')),
              const SizedBox(width: 12),
              Expanded(child: _MiniStat(label: 'Pesanan batal', value: '${r.cancelledCount}')),
            ]),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Penjualan per produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (r.rows.isEmpty)
                  const Text('Belum ada penjualan selesai di periode ini.', style: TextStyle(color: AppColors.muted))
                else
                  Table(
                    columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(0.9), 2: FlexColumnWidth(1.5)},
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                        children: [_H('Produk'), _H('Terjual', right: true), _H('Pendapatan', right: true)],
                      ),
                      for (final row in r.rows)
                        TableRow(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
                          children: [
                            _D(row.product),
                            _D('${row.qty}', right: true),
                            _D(rupiah(row.revenue), right: true),
                          ],
                        ),
                    ],
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(exportPdf, r),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Unduh PDF', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(exportExcel, r),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('Unduh Excel', style: TextStyle(fontSize: 14)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text, {this.right = false});
  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
      );
}

class _D extends StatelessWidget {
  const _D(this.text, {this.right = false});
  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, textAlign: right ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 14)),
      );
}
