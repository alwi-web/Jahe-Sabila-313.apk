import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
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
          Flexible(
            child: Text('Jahe Merah Sabila 313',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brown)),
          ),
        ]),
        actions: const [CartIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Sambutan: banner foto kemasan + panel merah, seperti banner promo toko online.
          _HeroBanner(onTap: toProducts),
          const SizedBox(height: 16),
          const Text(
            'Jahe Merah Sabila 313 diolah dari jahe merah pilihan dan bahan-bahan alami, '
            'dipanen dari perkebunan petani lokal, supaya kehangatan dan khasiatnya tetap terjaga '
            'di setiap seduhan.',
            style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.55),
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
            const SizedBox(height: 8),
            // Melebar sampai tepi layar supaya kartu samping tidak terpotong margin halaman.
            SizedBox(
              height: _VariantCarousel.height,
              child: OverflowBox(
                maxWidth: MediaQuery.sizeOf(context).width,
                child: _VariantCarousel(products: state.products),
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

/// Carousel varian: kartu di tengah tajam, kartu di kiri/kanan mengecil, memudar, dan blur.
/// Saat digeser, fokus berpindah halus mengikuti posisi geser.
class _VariantCarousel extends StatefulWidget {
  const _VariantCarousel({required this.products});

  final List<Product> products;

  /// Tinggi kartu (300) + jarak (10) + titik penanda (7).
  static const height = 317.0;

  @override
  State<_VariantCarousel> createState() => _VariantCarouselState();
}

class _VariantCarouselState extends State<_VariantCarousel> {
  // Mulai dari kartu kedua kalau ada 3 atau lebih, supaya kiri dan kanan langsung terlihat.
  late final int _start = widget.products.length >= 3 ? 1 : 0;
  late final _controller = PageController(viewportFraction: 0.62, initialPage: _start);
  late int _current = _start;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Product p) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    return Column(children: [
      SizedBox(
        height: 300,
        child: PageView.builder(
          controller: _controller,
          physics: const _SoftPagePhysics(),
          itemCount: products.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Jarak kartu ini dari tengah: 0 = fokus, 1 = satu kartu di samping.
              final page = _controller.hasClients && _controller.position.haveDimensions
                  ? _controller.page!
                  : _start.toDouble();
              final d = (page - i).abs().clamp(0.0, 1.0);
              final blur = d * 2.4;
              Widget card = Transform.scale(
                scale: 1 - d * 0.14,
                child: Opacity(opacity: 1 - d * 0.45, child: child),
              );
              if (blur > 0.05) {
                card = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: card);
              }
              return card;
            },
            // Kartu digambar sekali ke lapisannya sendiri; saat digeser hanya skala/opacity/blur yang dihitung ulang.
            child: RepaintBoundary(child: _VariantCard(product: products[i], onTap: () => _open(products[i]))),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < products.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _current ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _current ? AppColors.brand : AppColors.field,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ]),
    ]);
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => ProductPhoto(
                    product: product,
                    width: c.maxWidth,
                    height: c.maxHeight,
                    packWidth: c.maxHeight * 0.5,
                    radius: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text('Mulai ${rupiah(product.startingPrice)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: AppColors.brand),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Snap halaman dengan pegas yang lebih lembut daripada bawaan PageView.
class _SoftPagePhysics extends PageScrollPhysics {
  const _SoftPagePhysics({super.parent});

  @override
  _SoftPagePhysics applyTo(ScrollPhysics? ancestor) => _SoftPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 1, stiffness: 120, ratio: 1.0);
}

/// Banner sambutan: foto kemasan di kiri, panel merah berisi label halal, judul, dan tombol di kanan.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 210,
          child: LayoutBuilder(builder: (context, c) {
            final panelWidth = c.maxWidth * 0.58;
            return Stack(children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: c.maxWidth - panelWidth + 28,
                child: Image.asset(
                  'assets/banner_kemasan.jpg',
                  fit: BoxFit.cover,
                  semanticLabel: 'Kemasan Jahe Merah Sabila 313',
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: panelWidth,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brand, Color(0xFF7E2214)],
                    ),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified, size: 14, color: AppColors.success),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text('Bersertifikat Halal',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    const Text('Jahe Merah Asli dari Petani Lokal',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 6),
                    const Text('Hangat dan sehat, dari bahan-bahan alami.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: Color(0xFFF7DCD5), height: 1.35)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                          child: Text('Lihat produk',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
