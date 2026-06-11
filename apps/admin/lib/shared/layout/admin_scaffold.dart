import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../features/auth/auth_cubit.dart';

class AdminScaffold extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const AdminScaffold({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= OmnigoBreakpoints.medium;
    final sidebarWidth = width >= OmnigoBreakpoints.expanded ? 264.0 : 232.0;

    return Scaffold(
      backgroundColor: OmnigoColors.background,
      drawer: isWide
          ? null
          : Drawer(child: _SidebarContent(currentPath: currentPath)),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: sidebarWidth,
              child: _SidebarContent(currentPath: currentPath),
            ),
          Expanded(
            child: Column(
              children: [
                _AppBar(isWide: isWide),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final bool isWide;
  const _AppBar({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final isCompact = OmnigoBreakpoints.isCompact(context);

    return Container(
      height: isCompact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
      decoration: BoxDecoration(
        color: OmnigoColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (!isWide) const SizedBox(width: 8),
          const OmnigoLogo(
            size: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 10),
          Text(
            'OMNIGO Admin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: OmnigoColors.textPrimary,
            ),
          ),
          const Spacer(),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return Row(
                children: [
                  if (state.user?.email != null && !isCompact)
                    Text(
                      state.user!.email!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: OmnigoColors.primary.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 18,
                      color: OmnigoColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String currentPath;
  const _SidebarContent({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: OmnigoColors.surfaceWarm,
        border: Border(right: BorderSide(color: OmnigoColors.divider)),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const OmnigoLogo(
                  size: 36,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'OMNIGO',
                  style: TextStyle(
                    color: OmnigoColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Tổng quan',
                  path: '/dashboard',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Sản phẩm',
                  path: '/products',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Đơn hàng',
                  path: '/orders',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.people_outlined,
                  label: 'Khách hàng',
                  path: '/customers',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.warehouse_outlined,
                  label: 'Kho hàng',
                  path: '/inventory',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Báo cáo',
                  path: '/reports',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.badge_outlined,
                  label: 'Nhân viên',
                  path: '/employees',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.local_offer_outlined,
                  label: 'Voucher',
                  path: '/vouchers',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.campaign_outlined,
                  label: 'Thông báo',
                  path: '/broadcast',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Insights',
                  path: '/ai-analytics',
                  currentPath: currentPath,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Cài đặt',
                  path: '/settings',
                  currentPath: currentPath,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: () => context.read<AuthCubit>().signOut(),
              icon: const Icon(
                Icons.logout,
                color: OmnigoColors.textSecondary,
                size: 18,
              ),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: OmnigoColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive ? OmnigoColors.chipBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.go(path);
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? OmnigoColors.primary
                      : OmnigoColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? OmnigoColors.primary
                        : OmnigoColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
