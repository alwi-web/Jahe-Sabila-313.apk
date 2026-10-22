import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/common.dart';
import '../account/address_form_screen.dart';
import '../account/address_list_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _busy = false;

  Future<void> _confirm() async {
    final state = context.read<AppState>();
    if (state.mainAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan alamat pengiriman dulu')),
      );
      return;
    }
    setState(() => _busy = true);
    // 1. Simpan pesanan ke server dulu, 2. baru buka WhatsApp.
    Order? order;
    final ok = await runGuarded(context, () async => order = await state.placeOrder());
    if (!mounted) return;
    if (!ok || order == null) {
      setState(() => _busy = false);
      return;
    }
    final opened = await openWhatsApp(state.storeWhatsApp, buildOrderMessage(order!, state.profile));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order!, whatsAppOpened: opened)),
      (r) => r.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final address = state.mainAddress;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(children: [
            const Expanded(
              child: Text('Alamat pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            if (address != null)
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressListScreen())),
                child: const Text('Ganti'),
              ),
          ]),
          const SizedBox(height: 8),
          if (address == null)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddressFormScreen(address: state.newAddressDraft(), isNew: true)),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Tambah alamat pengiriman'),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(14),
              borderColor: AppColors.brand,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(address.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const MainBadge(),
                ]),
                const SizedBox(height: 8),
                Text(address.fullText, style: const TextStyle(fontSize: 14, height: 1.5)),
              ]),
            ),
          const SizedBox(height: 24),
          const Text('Ringkasan pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              for (final it in state.cart) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.product.name, style: const TextStyle(fontSize: 14, height: 1.4)),
                      Text('${it.variant.size.label} x ${it.qty}',
                          style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    ]),
                  ),
                  Text(rupiah(it.lineTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Text('Total (${state.cartCount} barang)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text(rupiah(state.cartTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
          onPressed: _busy || state.cartEmpty ? null : _confirm,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.chat_outlined),
          label: const Text('Konfirmasi via WhatsApp'),
        ),
        const SizedBox(height: 12),
        const Text('Pesanan disimpan, lalu WhatsApp terbuka dengan pesan otomatis',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}
