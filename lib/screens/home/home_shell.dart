import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../theme.dart';
import '../account/profile_screen.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';

/// Kerangka utama setelah login: Beranda, Keranjang, Akun.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = state.cartCount;
    return Scaffold(
      body: IndexedStack(
        index: state.tab,
        children: const [CatalogScreen(), CartScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tab,
        onDestinationSelected: state.setTab,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.cream,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.brand),
            label: 'Beranda',
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
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.brand),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
