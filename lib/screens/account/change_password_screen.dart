import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';
import '../auth/forgot_password_screen.dart';

/// Ubah password saat sedang login. Tombol kembali (pop) kembali ke Akun saya.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _oldError;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _oldError = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    var ok = false;
    final done = await runGuarded(context, () async {
      ok = await context.read<AppState>().changePassword(_old.text, _new.text);
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!done) return;
    if (!ok) {
      setState(() => _oldError = 'Password lama salah');
      _form.currentState!.validate();
      return;
    }
    Navigator.of(context).pop('Password berhasil diubah');
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AppState>().profile.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah password')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const Text('Masukkan password lama, lalu buat password baru untuk akunmu.',
                style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
            const SizedBox(height: 24),
            PasswordField(
              label: 'Password lama',
              controller: _old,
              hint: 'Masukkan password lama',
              validator: (v) => requiredField(v, 'Password lama') ?? _oldError,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: email)),
                ),
                child: const Text('Lupa password lama?'),
              ),
            ),
            PasswordField(label: 'Password baru', controller: _new, hint: 'Minimal 8 karakter',
                validator: (v) {
              final base = passwordValidator(v);
              if (base != null) return base;
              if (v == _old.text) return 'Password baru harus berbeda dari password lama';
              return null;
            }),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Ulangi password baru',
              controller: _confirm,
              hint: 'Ketik ulang password baru',
              textInputAction: TextInputAction.done,
              validator: (v) => v != _new.text ? 'Password tidak sama' : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        BusyButton(label: 'Simpan password baru', busy: _busy, onPressed: _save),
      ]),
    );
  }
}
