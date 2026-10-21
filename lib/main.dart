import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/app_state.dart';
import 'data/memory_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/router.dart';
import 'theme.dart';

/// Untuk menampilkan pesan error dari mana saja.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ShopRepository repo;
  if (supabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    repo = SupabaseRepository();
  } else {
    debugPrint('config.dart belum diisi: aplikasi berjalan dalam MODE DEMO.');
    repo = MemoryRepository();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        repo,
        onError: (msg) => messengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg))),
      ),
      child: const Sabila313App(),
    ),
  );
}

class Sabila313App extends StatelessWidget {
  const Sabila313App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jahe Merah Sabila 313',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scaffoldMessengerKey: messengerKey,
      home: const _StartGate(),
    );
  }
}

/// Memulihkan sesi login yang tersimpan, lalu membuka Beranda atau Login.
class _StartGate extends StatefulWidget {
  const _StartGate();

  @override
  State<_StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<_StartGate> {
  late final Future<bool> _boot = context.read<AppState>().bootstrap();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == true ? homeFor(context.read<AppState>()) : const LoginScreen();
      },
    );
  }
}
