import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../shared/layout/customer_responsive.dart';
import 'cart_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            // AppBar cream
            Container(
              color: _kBg,
              padding: CustomerResponsive.headerPadding(context),
              child: Row(
                children: [
                  const Text(
                    'Giỏ hàng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  if (state.items.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.read<CartCubit>().clearCart(),
                      child: const Text(
                        'Xóa tất cả',
                        style: TextStyle(color: _kPrimary, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: state.isEmpty
                  ? _buildEmpty(context)
                  : _buildList(context, state),
            ),
            if (!state.isEmpty) _buildCheckout(context, state),
          ],
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      color: _kBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Giỏ hàng trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 28),
            OmnigoButton(
              label: 'Khám phá sản phẩm',
              prefixIcon: Icons.shopping_bag_outlined,
              onPressed: () => context.go('/products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, CartState state) {
    final horizontal = CustomerResponsive.pagePadding(context).horizontal / 2;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 16),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _cartItem(context, state.items[i]),
    );
  }

  Widget _cartItem(BuildContext context, CartItem item) {
    final cubit = context.read<CartCubit>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFF5F5F5),
              child: item.thumbnail != null
                  ? Image.network(
                      item.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image, color: Color(0xFFCCCCCC)),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFFCCCCCC),
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(item.price),
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty controls
          Row(
            children: [
              _qtyBtn(
                Icons.remove,
                () => cubit.updateQuantity(item.productId, item.quantity - 1),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _qtyBtn(
                Icons.add,
                () => cubit.updateQuantity(item.productId, item.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF444444)),
      ),
    );
  }

  Widget _buildCheckout(BuildContext context, CartState state) {
    final horizontal = CustomerResponsive.pagePadding(context).horizontal / 2;
    return Container(
      padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.totalQuantity} sản phẩm',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _fmt(state.totalAmount),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OmnigoButton(
            label: 'Đặt hàng · ${_fmt(state.totalAmount)}',
            expanded: true,
            size: OmnigoButtonSize.large,
            onPressed: () => context.push('/checkout'),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}
