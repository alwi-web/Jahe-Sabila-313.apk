import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/common.dart';
import '../account/order_history_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order, required this.whatsAppOpened});

  final Order order;
  final bool whatsAppOpened;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text('Pesanan #${order.number} tersimpan',
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                whatsAppOpened
                    ? 'Kirim pesan di WhatsApp untuk mengonfirmasi pesanan. Status pesanan: Menunggu bayar.'
                    : 'WhatsApp belum terbuka. Tekan tombol di bawah untuk mengirim pesanan ke penjual.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Bayar sebelum ${dateTime(order.payBefore)}, atau pesanan dibatalkan otomatis.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.brand, fontWeight: FontWeight.w600, height: 1.5),
              ),
              if (!whatsAppOpened) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
                  onPressed: () => openWhatsApp(state.storeWhatsApp, buildOrderMessage(order, state.profile)),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Buka WhatsApp'),
                ),
              ],
            ]),
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(divider: false, children: [
        FilledButton(
          onPressed: () {
            state.setTab(AppState.tabAccount);
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
          },
          child: const Text('Lihat riwayat pesanan'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            state.setTab(AppState.tabHome);
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
          child: const Text('Kembali ke beranda'),
        ),
      ]),
    );
  }
}
