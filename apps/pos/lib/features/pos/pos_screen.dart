import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';
import 'widgets/product_grid.dart';
import 'widgets/cart_panel.dart';
import 'pos_cubit.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final api = ctx.read<PosAuthCubit>().api;
        return PosCubit(api)..loadProducts();
      },
      child: const _PosScreenBody(),
    );
  }
}

class _PosScreenBody extends StatelessWidget {
  const _PosScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OmnigoColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 760) {
                  return const Column(
                    children: [
                      Expanded(flex: 3, child: ProductGrid()),
                      SizedBox(height: 320, child: CartPanel()),
                    ],
                  );
                }

                final cartWidth = (constraints.maxWidth * 0.34).clamp(
                  320.0,
                  420.0,
                );
                return Row(
                  children: [
                    const Expanded(child: ProductGrid()),
                    const VerticalDivider(width: 1),
                    SizedBox(width: cartWidth, child: const CartPanel()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      height: isCompact ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
      decoration: BoxDecoration(
        color: OmnigoColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const OmnigoLogo(
            size: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 10),
          Text(
            isCompact ? 'POS' : 'OMNIGO POS',
            style: const TextStyle(
              color: OmnigoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _topBarButton(
            context,
            Icons.swap_horiz,
            'Ca làm',
            () => context.go('/shift'),
            compact: isCompact,
          ),
          SizedBox(width: isCompact ? 2 : 8),
          _topBarButton(
            context,
            Icons.history,
            'Lịch sử',
            () => context.go('/orders'),
            compact: isCompact,
          ),
          SizedBox(width: isCompact ? 2 : 8),
          _topBarButton(
            context,
            Icons.logout,
            'Thoát',
            () => context.read<PosAuthCubit>().signOut(),
            compact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _topBarButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    required bool compact,
  }) {
    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, color: OmnigoColors.primary, size: 20),
      );
    }

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: OmnigoColors.primary, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: OmnigoColors.primary, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}