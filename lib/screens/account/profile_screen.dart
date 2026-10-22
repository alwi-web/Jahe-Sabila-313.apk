import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home/router.dart';
import 'address_list_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'order_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _open(BuildContext context, Widget page) async {
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => page));
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(result),
      ));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await runGuarded(context, context.read<AppState>().signOut);
    if (!ok || !context.mounted) return;
    // Setelah keluar kembali ke Beranda sebagai tamu.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homeFor(context.read<AppState>())),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().profile;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Text('Akun saya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              UserAvatar(profile: profile),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.name.isEmpty ? 'Pengguna' : profile.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  if (profile.email.isNotEmpty)
                    Text(profile.email, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  if (profile.phone.isNotEmpty)
                    Text(profile.phone, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              _MenuTile(icon: Icons.edit_outlined, label: 'Ubah profil',
                  onTap: () => _open(context, const EditProfileScreen())),
              const Divider(indent: 14, endIndent: 14),
              _MenuTile(icon: Icons.location_on_outlined, label: 'Alamat pengiriman',
                  onTap: () => _open(context, const AddressListScreen())),
              const Divider(indent: 14, endIndent: 14),
              _MenuTile(icon: Icons.shopping_bag_outlined, label: 'Riwayat pesanan',
                  badge: context.watch<AppState>().unreadOrderUpdates,
                  onTap: () => _open(context, const OrderHistoryScreen())),
              const Divider(indent: 14, endIndent: 14),
              _MenuTile(icon: Icons.lock_outline, label: 'Ubah password',
                  onTap: () => _open(context, const ChangePasswordScreen())),
            ]),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: Color(0xFFE3B8AE)),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar akun'),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Angka merah di kanan, misalnya jumlah pesanan yang baru diperbarui.
  final int badge;

  @override
  Widget build(BuildContext context) {
    // Material sendiri supaya efek sentuh terlihat di atas kartu putih.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        minTileHeight: 56,
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.brown),
        ),
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (badge > 0) Badge(label: Text('$badge'), backgroundColor: AppColors.brand),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}
