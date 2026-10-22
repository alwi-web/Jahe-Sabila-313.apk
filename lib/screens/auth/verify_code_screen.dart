import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../utils/errors.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'new_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Masukkan 6 digit kode');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().verifyResetCode(widget.email, code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewPasswordScreen(email: widget.email, code: code)),
    );
  }

  Future<void> _resend() async {
    final ok = await runGuarded(context, () => context.read<AppState>().sendResetCode(widget.email));
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kode baru dikirim ke ${widget.email}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          AuthHeader(
            title: 'Masukkan kode',
            subtitle: 'Kode unik 6 digit sudah dikirim ke ${widget.email}. Periksa juga folder spam.',
            showBrand: false,
          ),
          const SizedBox(height: 32),
          const Text('Kode unik', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 14),
            decoration: InputDecoration(counterText: '', hintText: '••••••', errorText: _error),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 24),
          BusyButton(label: 'Verifikasi kode', busy: _busy, onPressed: _verify),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Belum menerima kode?', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            TextButton(onPressed: _resend, child: const Text('Kirim ulang')),
          ]),
        ],
      ),
    );
  }
}
