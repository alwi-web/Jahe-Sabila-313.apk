import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  bool _busy = false;
  late String _courier = widget.order.courier;
  late final _resi = TextEditingController(text: widget.order.trackingNumber);

  Order get o => widget.order;

  static const _couriers = ['JNE', 'J&T'];

  @override
  void dispose() {
    _resi.dispose();
    super.dispose();
  }

  Future<void> _saveShipping() async {
    final resi = _resi.text.trim();
    if (resi.isNotEmpty && _courier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kurir dulu')));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().setShipping(o, resi.isEmpty ? '' : _courier, resi));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resi.isEmpty ? 'Resi dihapus' : 'Resi $_courier $resi disimpan')),
      );
    }
  }

  Future<void> _setStatus(OrderStatus status) async {
    if (status == o.status || _busy) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().setOrderStatus(o, status));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pesanan #${o.number}: ${status.label}')),
      );
    }
  }

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan pesanan #${o.number}?'),
        content: const Text('Status berubah menjadi Dibatalkan dan stok barangnya dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (yes == true) await _setStatus(OrderStatus.cancelled);
  }

  Future<void> _contact() async {
    final number = normalizeWhatsAppNumber(o.buyerPhone);
    final uri = Uri.https('wa.me', number.isEmpty ? '/' : '/$number', {'text': buildAdminOrderMessage(o)});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp tidak bisa dibuka')));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>(); // ikut diperbarui saat status berubah
    final canCancel = o.status == OrderStatus.waitingPayment || o.status == OrderStatus.processing;

    return Scaffold(
      appBar: AppBar(title: Text('Pesanan #${o.number}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(children: [
            Expanded(child: Text(shortDate(o.date), style: const TextStyle(fontSize: 14, color: AppColors.muted))),
            StatusPill(o.status),
          ]),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Pembeli', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${o.buyerName.isEmpty ? 'Pembeli' : o.buyerName}${o.buyerPhone.isEmpty ? '' : ' · ${o.buyerPhone}'}',
                  style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 4),
              Text(o.addressText, style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp, minimumSize: const Size.fromHeight(44)),
                onPressed: _contact,
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Hubungi via WhatsApp', style: TextStyle(fontSize: 14)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Isi pesanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              for (final l in o.lines) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.productName, style: const TextStyle(fontSize: 14, height: 1.4)),
                      Text('${l.size.label} x ${l.qty}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ]),
                  ),
                  Text(rupiah(l.total), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
              ],
              const Divider(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text('Total (${o.itemCount} barang)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(rupiah(o.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Pengiriman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(children: [
                for (final c in _couriers) ...[
                  Expanded(
                    child: SelectPill(label: c, selected: _courier == c, onTap: () => setState(() => _courier = c)),
                  ),
                  if (c != _couriers.last) const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Nomor resi',
                controller: _resi,
                hint: 'Contoh: JP1234567890',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: _busy ? null : _saveShipping,
                child: const Text('Simpan resi'),
              ),
              const SizedBox(height: 6),
              const Text('Setelah disimpan, resi tampil di riwayat pesanan pembeli dan ikut di pesan WhatsApp.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Ubah status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.6,
            children: [
              for (final s in OrderStatus.values)
                SelectPill(label: s.label, selected: s == o.status, onTap: () => _setStatus(s)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Cek transfer secara manual, lalu ubah status ke Diproses. Perubahan langsung terlihat di aplikasi pembeli.',
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
          if (canCancel) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: Color(0xFFE3B8AE)),
              ),
              onPressed: _busy ? null : _cancel,
              child: const Text('Batalkan pesanan'),
            ),
          ],
        ],
      ),
    );
  }
}
