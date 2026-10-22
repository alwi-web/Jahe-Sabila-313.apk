import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../catalog/product_detail_screen.dart';

/// Beranda: halaman pertama yang dilihat semua orang, termasuk tamu yang belum login.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    void toProducts() => state.setTab(AppState.tabProducts);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(children: [
          BrandLogo(height: 36),
          SizedBox(width: 10),
          Text('Jahe Merah Sabila 313', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brown)),
        ]),
        actions: const [CartIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Sambutan
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: BrandLogo(height: 96)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(999)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_outlined, size: 16, color: AppColors.success),
                  SizedBox(width: 6),
                  Text('Bersertifikat Halal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                ]),
              ),
              const SizedBox(height: 12),
              const Text('Hangatnya jahe merah asli, langsung dari kebun petani lokal',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25)),
              const SizedBox(height: 10),
              const Text(
                'Jahe Merah Sabila 313 diolah dari jahe merah pilihan dan bahan-bahan alami, '
                'dipanen dari perkebunan petani lokal, supaya kehangatan dan khasiatnya tetap terjaga '
                'di setiap seduhan.',
                style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.55),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: toProducts,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Lihat produk'),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Keunggulan
          const Text('Kenapa memilih Sabila 313?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _Feature(
            icon: Icons.verified_outlined,
            title: 'Bersertifikat halal',
            text: 'Sudah bersertifikat halal, jadi aman dan tenang dinikmati seluruh keluarga.',
          ),
          const _Feature(
            icon: Icons.eco_outlined,
            title: 'Bahan-bahan alami',
            text: 'Dibuat dari jahe merah pilihan dan bahan-bahan alami.',
          ),
          const _Feature(
            icon: Icons.agriculture_outlined,
            title: 'Dari petani lokal',
            text: 'Jahe merah dipanen dari perkebunan dan petani lokal. Setiap pembelian ikut mendukung mereka.',
          ),
          const _Feature(
            icon: Icons.spa_outlined,
            title: 'Khasiat terjaga',
            text: 'Diolah dengan cermat agar khasiat alami jahe merah tetap terjaga sampai ke cangkirmu.',
          ),
          const SizedBox(height: 16),

          // Varian produk
          if (state.products.isNotEmpty) ...[
            Row(children: [
              const Expanded(
                child: Text('Pilihan varian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              TextButton(onPressed: toProducts, child: const Text('Lihat semua')),
            ]),
            const SizedBox(height: 4),
            for (final p in state.products.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    leading: ProductThumb(size: 48, product: p),
                    title: Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text('Mulai ${rupiah(p.startingPrice)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
          ],

          // Cara memesan
          const Text('Cara memesan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _Step(number: 1, text: 'Pilih varian dan ukuran (250 g, 500 g, atau 1 kg), lalu masukkan ke keranjang.'),
          const _Step(number: 2, text: 'Checkout. Detail pesananmu otomatis terkirim ke WhatsApp toko.'),
          const _Step(number: 3, text: 'Transfer sesuai info dari admin, lalu kirim bukti transfer di WhatsApp.'),
          const _Step(number: 4, text: 'Pantau status dan nomor resi JNE/J&T di Riwayat pesanan.'),
          const SizedBox(height: 20),

          FilledButton(onPressed: toProducts, child: const Text('Mulai belanja')),
          if (!state.loggedIn) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen(returnAfterLogin: true)),
              ),
              child: const Text('Masuk atau daftar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.45)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.brand,
          child: Text('$number', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.45))),
      ]),
    );
  }
}
