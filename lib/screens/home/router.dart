import 'package:flutter/widgets.dart';

import '../../data/app_state.dart';
import '../admin/admin_shell.dart';
import 'home_shell.dart';

/// Halaman utama sesuai peran akun (profiles.role): admin atau pembeli.
Widget homeFor(AppState state) => state.isAdmin ? const AdminShell() : const HomeShell();
