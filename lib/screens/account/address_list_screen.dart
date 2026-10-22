import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'address_form_screen.dart';

/// Daftar alamat. Dibuka dari Akun saya maupun dari Checkout ("Ganti");
/// tombol kembali selalu kembali ke layar asal.
class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.addresses;

    return Scaffold(
      appBar: AppBar(title: const Text('Alamat pengiriman')),
      body: list.isEmpty
          ? const Center(
              child: Text('Belum ada alamat. Tambahkan alamat pengiriman pertama.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = list[i];
                final main = state.isMain(a);
                return AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 4),
                  borderColor: main ? AppColors.brand : null,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(children: [
                        Expanded(child: Text(a.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                        if (main) const MainBadge(),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text(a.fullText, style: const TextStyle(fontSize: 14, height: 1.5)),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddressFormScreen(address: a, isNew: false)),
                        ),
                        child: const Text('Ubah'),
                      ),
                      if (!main)
                        TextButton(
                          onPressed: () => runGuarded(context, () => state.setMainAddress(a.id)),
                          child: const Text('Jadikan utama'),
                        ),
                    ]),
                  ]),
                );
              },
            ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddressFormScreen(address: state.newAddressDraft(), isNew: true)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tambah alamat baru'),
        ),
      ]),
    );
  }
}
