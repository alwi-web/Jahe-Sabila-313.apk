import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../utils/whatsapp.dart';
import '../../widgets/common.dart';

/// Pengaturan toko: nomor WhatsApp tujuan pesanan pembeli.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _form = GlobalKey<FormState>();
  late final _wa = TextEditingController(text: context.read<AppState>().storeWhatsApp);
  bool _busy = false;

  @override
  void dispose() {
    _wa.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final n = normalizeWhatsAppNumber(v ?? '');
    if (n.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (!n.startsWith('62') || n.length < 10 || n.length > 15) return 'Contoh nomor yang benar: 081234567890';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final ok = await runGuarded(context, () => state.saveStoreWhatsApp(_wa.text));
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _wa.text = state.storeWhatsApp;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nomor WhatsApp toko disimpan: ${state.storeWhatsApp}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan toko')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            LabeledField(
              label: 'Nomor WhatsApp toko',
              controller: _wa,
              hint: 'Contoh: 081234567890',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: _validate,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan pembeli dikirim ke nomor ini saat checkout. Perubahan berlaku untuk pembeli '
              'setelah mereka masuk ulang atau membuka ulang aplikasi.',
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Simpan')),
      ]),
    );
  }
}
