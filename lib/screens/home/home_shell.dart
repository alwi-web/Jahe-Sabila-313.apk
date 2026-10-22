import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../account/profile_screen.dart';
import '../auth/require_login.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';
import 'landing_screen.dart';

/// Kerangka utama pembeli dan tamu: Beranda, Produk, Keranjang, Akun.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = state.cartCount;
    final updates = state.unreadOrderUpdates;
    return Scaffold(
      body: IndexedStack(
        index: state.tab,
        children: const [LandingScreen(), CatalogScreen(), CartScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: NavigationBar(
        selectedIndex: state.tab,
        onDestinationSelected: (i) async {
          // Keranjang dan Akun butuh login; tamu diarahkan ke halaman Masuk dulu.
          final needsAccount = i == AppState.tabCart || i == AppState.tabAccount;
          if (needsAccount && !await requireLogin(context)) return;
          state.setTab(i);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.brand),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.brand),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.shopping_cart, color: AppColors.brand),
            ),
            label: 'Keranjang',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: updates > 0,
              label: Text('$updates'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.person_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: updates > 0,
              label: Text('$updates'),
              backgroundColor: AppColors.brand,
              child: const Icon(Icons.person, color: AppColors.brand),
            ),
            label: 'Akun',
          ),
        ],
      ),
      ),
    );
  }
}
