import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import 'login_screen.dart';

/// Untuk aksi yang butuh akun (keranjang, akun): tamu diarahkan ke halaman Masuk.
/// Mengembalikan true kalau pengguna sudah/berhasil login dan halaman ini masih terbuka.
Future<bool> requireLogin(BuildContext context) async {
  final state = context.read<AppState>();
  if (state.loggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen(returnAfterLogin: true)),
  );
  return ok == true && context.mounted && state.loggedIn;
}
