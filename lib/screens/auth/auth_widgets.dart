import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle, this.showBrand = true});

  final String title;
  final String subtitle;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showBrand) ...[
        const BrandLogo(),
        const SizedBox(height: 16),
        const Text('Jahe Merah Sabila 313',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brown)),
        const SizedBox(height: 6),
      ],
      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
    ]);
  }
}

/// Baris "Belum punya akun? Daftar" di bagian bawah layar.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.text, required this.action, required this.onPressed});

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          TextButton(onPressed: onPressed, child: Text(action)),
        ]),
      ),
    );
  }
}

/// Tombol utama yang menampilkan indikator saat proses berjalan.
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Text(label),
    );
  }
}
