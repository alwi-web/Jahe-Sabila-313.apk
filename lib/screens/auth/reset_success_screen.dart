import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 44, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              const Text('Password berhasil diubah',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Silakan masuk kembali menggunakan password baru.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5)),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(divider: false, children: [
        FilledButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          ),
          child: const Text('Masuk kembali'),
        ),
      ]),
    );
  }
}
