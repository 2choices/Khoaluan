import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'customer_responsive.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class CustomerShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const CustomerShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final useRail = CustomerResponsive.useRailNavigation(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (i) => _onTap(context, i),
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFFFE5D9),
                  selectedIconTheme: const IconThemeData(color: _kPrimary),
                  selectedLabelTextStyle: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: Color(0xFF999999),
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF777777),
                  ),
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(width: 1, color: Color(0xFFEFE3DC)),
                Expanded(
                  child: CustomerResponsivePane(child: child),
                ),
              ],
            )
          : child,
      bottomNavigationBar: useRail
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => _onTap(context, i),
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                indicatorColor: const Color(0xFFFFE5D9),
                height: 64,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: _barDestinations,
              ),
            ),
    );
  }

  List<NavigationDestination> get _barDestinations {
    return const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined, color: Color(0xFF999999)),
        selectedIcon: Icon(Icons.home, color: _kPrimary),
        label: 'Trang chủ',
      ),
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined, color: Color(0xFF999999)),
        selectedIcon: Icon(Icons.grid_view, color: _kPrimary),
        label: 'Sản phẩm',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF999999)),
        selectedIcon: Icon(Icons.receipt_long, color: _kPrimary),
        label: 'Đơn hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF999999)),
        selectedIcon: Icon(Icons.shopping_cart, color: _kPrimary),
        label: 'Giỏ hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, color: Color(0xFF999999)),
        selectedIcon: Icon(Icons.person, color: _kPrimary),
        label: 'Cá nhân',
      ),
    ];
  }

  List<NavigationRailDestination> get _railDestinations {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Trang chủ'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: Text('Sản phẩm'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Đơn hàng'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: Text('Giỏ hàng'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Cá nhân'),
      ),
    ];
  }

  int get _currentIndex {
    if (currentPath.startsWith('/home')) return 0;
    if (currentPath.startsWith('/products')) return 1;
    if (currentPath.startsWith('/orders')) return 2;
    if (currentPath.startsWith('/cart')) return 3;
    if (currentPath.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    final paths = ['/home', '/products', '/orders', '/cart', '/profile'];
    final target = paths[index];

    if (currentPath == target || currentPath.startsWith('$target/')) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(target);
    });
  }
}