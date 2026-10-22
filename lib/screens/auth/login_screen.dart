import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../widgets/common.dart';
import '../home/router.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnAfterLogin = false});

  /// true = dibuka dari aksi yang butuh login (mis. tambah ke keranjang):
  /// setelah pembeli login, kembali ke halaman sebelumnya dengan hasil true.
  final bool returnAfterLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runGuarded(
      context,
      () => context.read<AppState>().signIn(_email.text.trim(), _password.text),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    final state = context.read<AppState>();
    if (widget.returnAfterLogin && !state.isAdmin) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homeFor(state)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canGoBack ? AppBar() : null,
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            children: [
              const AuthHeader(title: 'Masuk', subtitle: 'Masuk untuk mulai berbelanja'),
              const SizedBox(height: 28),
              LabeledField(
                label: 'Email',
                controller: _email,
                hint: 'nama@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),
              const SizedBox(height: 16),
              PasswordField(
                label: 'Password',
                controller: _password,
                hint: 'Masukkan password',
                textInputAction: TextInputAction.done,
                validator: (v) => requiredField(v, 'Password'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Lupa password?'),
                ),
              ),
              const SizedBox(height: 4),
              BusyButton(label: 'Masuk', busy: _busy, onPressed: _submit),
              if (!canGoBack) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => homeFor(context.read<AppState>())),
                    (_) => false,
                  ),
                  child: const Text('Lihat produk tanpa masuk'),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AuthFooterLink(
        text: 'Belum punya akun?',
        action: 'Daftar',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
      ),
    );
  }
}
