import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'verify_code_screen.dart';

/// Dipakai dari layar Login (belum masuk) dan dari Ubah password (sudah masuk).
/// Tombol kembali selalu kembali ke layar asal karena memakai Navigator.pop.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().sendResetCode(_email.text.trim()));
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: _email.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            const AuthHeader(
              title: 'Lupa password',
              subtitle: 'Masukkan email akunmu. Kami kirim kode unik lewat email untuk mengatur ulang password.',
              showBrand: false,
            ),
            const SizedBox(height: 32),
            LabeledField(
              label: 'Email',
              controller: _email,
              hint: 'nama@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: emailValidator,
            ),
            const SizedBox(height: 16),
            BusyButton(label: 'Kirim kode', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
