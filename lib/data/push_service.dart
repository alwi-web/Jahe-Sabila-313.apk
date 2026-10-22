import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'app_state.dart';

/// Push notification lewat Firebase Cloud Messaging.
///
/// Setelah login, token HP disimpan ke Supabase (tabel perangkat_notif) supaya
/// Edge Function "kirim-notif" bisa mengirim notifikasi ke HP ini; saat keluar,
/// token dihapus. Notifikasi yang masuk saat aplikasi terbuka ditampilkan lewat
/// [showMessage] dan data pesanan dimuat ulang.
class PushService {
  PushService(this.state, {required this.showMessage});

  final AppState state;
  final void Function(String message) showMessage;

  String? _token;
  String? _registeredFor;

  Future<void> start() async {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
    } catch (e) {
      debugPrint('Firebase tidak bisa dimulai, push notification nonaktif: $e');
      return;
    }
    final fm = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _refresh());
    // Token FCM klasik: dikirim lewat FCM HTTP v1 (`message.token`) dari Edge Function.
    // getToken/onTokenRefresh ditandai usang di firebase_messaging 17 (diganti register()
    // + Installation ID) tetapi masih berfungsi; ganti bersamaan dengan Edge Function nanti.
    // ignore: deprecated_member_use
    fm.onTokenRefresh.listen((t) {
      _token = t;
      if (state.loggedIn) _guard(() => state.repo.saveDeviceToken(t));
    });
    state.onBeforeSignOut = _unregister;
    state.addListener(_syncWithSession);
    unawaited(_syncWithSession());
  }

  /// Daftarkan token setiap kali akun yang login berganti.
  Future<void> _syncWithSession() async {
    final uid = state.loggedIn ? state.profile.id : null;
    if (uid == null || uid == _registeredFor) return;
    _registeredFor = uid;
    await _guard(() async {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(); // dialog izin di Android 13+
      // ignore: deprecated_member_use
      _token ??= await fm.getToken();
      if (_token != null) await state.repo.saveDeviceToken(_token!);
    });
  }

  Future<void> _unregister() async {
    final t = _token;
    _registeredFor = null;
    if (t != null) await _guard(() => state.repo.removeDeviceToken(t));
  }

  void _onForeground(RemoteMessage m) {
    final n = m.notification;
    if (n != null) showMessage([n.title, n.body].whereType<String>().join(' · '));
    _refresh();
  }

  void _refresh() {
    if (!state.loggedIn) return;
    unawaited(_guard(state.isAdmin ? state.loadAdminOrders : state.loadOrders));
  }

  static Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Push notification: $e');
    }
  }
}
