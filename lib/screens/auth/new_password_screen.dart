import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'reset_success_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.email, required this.code});

  final String email;
  final String code;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () => context.read<AppState>().setNewPassword(_password.text));
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    // Setelah reset, semua halaman sebelumnya ditutup dan pengguna wajib login ulang.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ResetSuccessScreen()),
      (_) => false,
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
              title: 'Buat password baru',
              subtitle: 'Kode terverifikasi. Buat password baru, lalu masuk kembali dengan password itu.',
              showBrand: false,
            ),
            const SizedBox(height: 28),
            PasswordField(label: 'Password baru', controller: _password, hint: 'Minimal 8 karakter',
                validator: passwordValidator),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Ulangi password baru',
              controller: _confirm,
              hint: 'Ketik ulang password baru',
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'Password tidak sama' : null,
            ),
            const SizedBox(height: 20),
            BusyButton(label: 'Simpan password baru', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
