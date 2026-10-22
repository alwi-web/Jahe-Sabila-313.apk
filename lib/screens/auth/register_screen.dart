import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../widgets/common.dart';
import '../home/router.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    var loggedIn = false;
    final ok = await runGuarded(context, () async {
      loggedIn = await context.read<AppState>().signUp(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
          );
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    if (!loggedIn) {
      // Supabase meminta konfirmasi email sebelum bisa masuk.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cek email kamu'),
          content: Text('Kami mengirim link konfirmasi ke ${_email.text.trim()}. '
              'Buka link itu, lalu masuk dengan email dan password yang baru dibuat.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homeFor(context.read<AppState>())),
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const AuthHeader(title: 'Buat akun', subtitle: 'Isi data diri untuk mulai berbelanja'),
            const SizedBox(height: 24),
            LabeledField(label: 'Nama lengkap', controller: _name, hint: 'Nama lengkap',
                validator: (v) => requiredField(v, 'Nama')),
            const SizedBox(height: 16),
            LabeledField(label: 'Email', controller: _email, hint: 'nama@email.com',
                keyboardType: TextInputType.emailAddress, validator: emailValidator),
            const SizedBox(height: 16),
            LabeledField(label: 'Nomor HP', controller: _phone, hint: '08xxxxxxxxxx',
                keyboardType: TextInputType.phone, validator: (v) => requiredField(v, 'Nomor HP')),
            const SizedBox(height: 16),
            PasswordField(label: 'Password', controller: _password, hint: 'Buat password',
                validator: passwordValidator),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Ulangi password',
              controller: _confirm,
              hint: 'Ketik ulang password',
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'Password tidak sama' : null,
            ),
            const SizedBox(height: 24),
            BusyButton(label: 'Daftar', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
      bottomNavigationBar: AuthFooterLink(
        text: 'Sudah punya akun?',
        action: 'Masuk',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
