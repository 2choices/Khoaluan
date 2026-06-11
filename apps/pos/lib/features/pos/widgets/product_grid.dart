import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../pos_cubit.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosCubit, PosState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: OmnigoLoading(message: 'Đang tải sản phẩm...'));
        }

        return Column(
          children: [
            _buildSearchAndCategories(context, state),
            Expanded(child: _buildGrid(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndCategories(BuildContext context, PosState state) {
    return Container(
      padding: EdgeInsets.all(OmnigoBreakpoints.isCompact(context) ? 10 : 12),
      color: OmnigoColors.background,
      child: Column(
        children: [
          OmnigoTextField(
            hint: 'Tìm sản phẩm...',
            prefixIcon: Icons.search,
            onChanged: (v) => context.read<PosCubit>().setSearch(v),
          ),
          if (state.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip(context, 'Tất cả', null, state.selectedCategory == null),
                  ...state.categories.map((cat) => _categoryChip(
                    context,
                    cat['name'] ?? '',
                    cat['id']?.toString(),
                    state.selectedCategory == cat['id']?.toString(),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String label, String? id, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? OmnigoColors.primary : const Color(0xFF555555),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFFFD5C2),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? OmnigoColors.primary : const Color(0xFFCCCCCC),
          width: isSelected ? 1.5 : 1,
        ),
        onSelected: (_) => context.read<PosCubit>().setCategory(id),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildGrid(BuildContext context, PosState state) {
    final products = state.filteredProducts;
    if (products.isEmpty) {
      return const Center(child: Text('Không tìm thấy sản phẩm'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = (constraints.maxWidth / 170).floor().clamp(2, 6).toInt();
        final aspectRatio = constraints.maxWidth < 520 ? 0.82 : 0.9;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => _productCard(context, products[i]),
        );
      },
    );
  }

  Widget _productCard(BuildContext context, Map<String, dynamic> product) {
    final price = (product['base_price'] as num?)?.toDouble() ??
      (product['price'] as num?)?.toDouble() ??
      0;
    final imageUrl = _imageUrl(product);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<PosCubit>().addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: OmnigoColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _PlaceholderIcon(),
                        ),
                      )
                    : const _PlaceholderIcon(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: OmnigoColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }

  String? _imageUrl(Map<String, dynamic> product) {
    final thumbnail = product['thumbnail'];
    if (thumbnail is String && thumbnail.isNotEmpty) return thumbnail;

    final images = product['images'];
    if (images is List && images.isNotEmpty && images.first is Map) {
      final first = images.first as Map;
      return (first['thumbnail_url'] ?? first['url'])?.toString();
    }
    return null;
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.inventory_2_outlined, size: 32, color: OmnigoColors.primary),
    );
  }
}
