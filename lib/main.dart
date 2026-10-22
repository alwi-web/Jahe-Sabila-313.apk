import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/app_state.dart';
import 'data/memory_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'screens/home/router.dart';
import 'theme.dart';

/// Untuk menampilkan pesan error dari mana saja.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Boot());
}

/// Menyiapkan Supabase (atau mode demo) sambil menampilkan layar memuat.
/// Kalau gagal, pesan error ditampilkan di layar alih-alih layar hitam.
class _Boot extends StatefulWidget {
  const _Boot();

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  late Future<ShopRepository> _repo = _initRepo();

  static Future<ShopRepository> _initRepo() async {
    if (!supabaseConfigured) {
      debugPrint('config.dart belum diisi: aplikasi berjalan dalam MODE DEMO.');
      return MemoryRepository();
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey)
        .timeout(const Duration(seconds: 20));
    return SupabaseRepository();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopRepository>(
      future: _repo,
      builder: (context, snap) {
        if (snap.hasData) {
          return ChangeNotifierProvider(
            create: (_) => AppState(
              snap.data!,
              onError: (msg) => messengerKey.currentState
                ?..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(msg))),
            ),
            child: const Sabila313App(),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: Scaffold(
            body: Center(
              child: snap.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Gagal memulai aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('${snap.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => _repo = _initRepo()),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
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

/// Memulihkan sesi login yang tersimpan, lalu membuka Beranda (pembeli/tamu) atau dashboard admin.
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
        // Tamu juga langsung masuk ke Beranda; login diminta saat berbelanja.
        return homeFor(context.read<AppState>());
      },
    );
  }
}
