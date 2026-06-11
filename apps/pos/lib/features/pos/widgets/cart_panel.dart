import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../pos_cubit.dart';
import 'payment_dialog.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        return Container(
          color: OmnigoColors.surface,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 20, color: OmnigoColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Giỏ hàng (${state.cartItemCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    if (state.cart.isNotEmpty)
                      TextButton(
                        onPressed: () => context.read<PosCubit>().clearCart(),
                        child: const Text('Xóa', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: state.cart.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Giỏ hàng trống', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.cart.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => _cartItemTile(context, state.cart[i]),
                      ),
              ),
              // ── AI Basket Suggestions ────────────────────────
              if (state.cart.isNotEmpty) _buildBasketSuggestions(context, state),
              _buildCheckoutSection(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _cartItemTile(BuildContext context, CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  _formatPrice(item.price),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(
                Icons.remove,
                () => context.read<PosCubit>().updateQuantity(item.id, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _qtyButton(
                Icons.add,
                () => context.read<PosCubit>().updateQuantity(item.id, item.quantity + 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              _formatPrice(item.total),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildBasketSuggestions(BuildContext context, PosState state) {
    if (state.loadingBasket) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F0),
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: OmnigoColors.primary)),
            SizedBox(width: 8),
            Text('Đang tìm combo phù hợp...', style: TextStyle(fontSize: 12, color: OmnigoColors.textSecondary)),
          ],
        ),
      );
    }
    if (state.basketSuggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F0),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: OmnigoColors.primary),
              SizedBox(width: 4),
              Text('Thêm vào để tạo combo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OmnigoColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.basketSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = state.basketSuggestions[i];
                final price = (p['base_price'] as num?)?.toDouble() ??
                    (p['price'] as num?)?.toDouble() ?? 0;
                return GestureDetector(
                  onTap: () => context.read<PosCubit>().addToCart(p),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OmnigoColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p['name']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _formatPrice(price),
                                style: const TextStyle(fontSize: 11, color: OmnigoColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.add_circle_outline, size: 18, color: OmnigoColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, PosState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OmnigoColors.surfaceWarm,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng:', style: TextStyle(fontSize: 16)),
              Text(
                _formatPrice(state.cartTotal),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: OmnigoColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.cart.isEmpty
                  ? null
                  : () => showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<PosCubit>(),
                          child: PaymentDialog(total: state.cartTotal),
                        ),
                      ),
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: OmnigoColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}
