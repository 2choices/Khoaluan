import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../ai/ai_cubit.dart';
import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  int _quantity = 1;
  bool _isFavorite = false;

  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
    // Load AI similar products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AiCubit>().loadSimilarProducts(widget.productId);
      }
    });
  }

  Future<void> _loadReviews() async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get<dynamic>('/reviews/product/${widget.productId}');
      final raw = res.data;
      Map data = {};
      if (raw is Map && raw['data'] != null) {
        final lvl1 = raw['data'];
        data = lvl1 is Map && lvl1['data'] is Map
            ? lvl1['data'] as Map
            : (lvl1 is Map ? lvl1 : {});
      } else if (raw is Map) {
        data = raw;
      }
      final list = data['data'];
      if (mounted) {
        setState(() {
          _reviews = list is List
              ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : [];
          _avgRating = (data['average'] as num?)?.toDouble() ?? 0;
          _totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProduct() async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final response = await api.get('/catalog/products/${widget.productId}');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          _product = data is Map ? Map<String, dynamic>.from(data) : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _price =>
      (_product?['base_price'] as num?)?.toDouble() ??
      (_product?['price'] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
        ),
        title: Text(
          _product?['name'] ?? 'Chi tiết sản phẩm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Cart badge
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (cartState.totalQuantity > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                        child: Text(
                          '${cartState.totalQuantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? _kPrimary : const Color(0xFF888888),
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: OmnigoLoading())
          : _product == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('Không tìm thấy sản phẩm', style: TextStyle(color: Color(0xFF888888))),
                      const SizedBox(height: 16),
                      OmnigoButton(label: 'Quay lại', onPressed: () => context.go('/products')),
                    ],
                  ),
                )
              : _buildBody(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    final stockQty = (_product!['stock_quantity'] as num?)?.toInt() ?? 0;
    final inStock = stockQty > 0 || _product!['allow_sell_when_out_of_stock'] == true;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 280,
            width: double.infinity,
            color: Colors.white,
            child: Builder(builder: (_) {
              String? imgUrl = _product!['thumbnail'] as String?;
              if (imgUrl == null) {
                final images = _product!['images'];
                if (images is List && images.isNotEmpty) {
                  final primary = images.firstWhere(
                    (img) => img['is_primary'] == true,
                    orElse: () => images.first,
                  );
                  imgUrl = primary['url'] as String? ?? primary['thumbnail_url'] as String?;
                }
              }
              return imgUrl != null
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Center(child: Icon(Icons.image, size: 64, color: Color(0xFFCCCCCC))),
                    )
                  : const Center(
                      child: Icon(Icons.inventory_2_outlined, size: 72, color: Color(0xFFCCCCCC)),
                    );
            }),
          ),

          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        inStock ? 'Còn hàng' : 'Hết hàng',
                        style: TextStyle(
                          color: inStock ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_product!['sku'] != null) ...[
                      const SizedBox(width: 8),
                      Text('SKU: ${_product!['sku']}', style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _product!['name'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatPrice(_price),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kPrimary),
                ),
              ],
            ),
          ),

          // Description
          if (_product!['description'] != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  Text(
                    _product!['description'] as String,
                    style: const TextStyle(color: Color(0xFF555555), height: 1.6),
                  ),
                ],
              ),
            ),
          ],

          // Quantity selector
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Row(
              children: [
                const Text('Số lượng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                _qtyBtn(Icons.remove, _quantity > 1 ? () => setState(() => _quantity--) : null),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _qtyBtn(Icons.add, () => setState(() => _quantity++)),
              ],
            ),
          ),

          _buildReviewsSection(),

          // ── Sản phẩm tương tự (AI) ────────────────────────
          BlocBuilder<AiCubit, AiState>(
            builder: (context, aiState) {
              if (aiState.loadingSimilar) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: OmnigoLoading()),
                );
              }
              if (aiState.similarProducts.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16, color: _kPrimary),
                        const SizedBox(width: 6),
                        const Text('Sản phẩm tương tự',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: aiState.similarProducts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final p = aiState.similarProducts[i];
                          final price = (p['base_price'] as num?)?.toDouble() ??
                              (p['price'] as num?)?.toDouble() ?? 0;
                          String? img = p['thumbnail'] as String?;
                          if (img == null) {
                            final imgs = p['images'];
                            if (imgs is List && imgs.isNotEmpty) {
                              img = imgs.first['thumbnail_url'] as String? ?? imgs.first['url'] as String?;
                            }
                          }
                          return GestureDetector(
                            onTap: () => context.go('/product/${p['id']}'),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEEEEEE)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: SizedBox(
                                      height: 90,
                                      width: double.infinity,
                                      child: img != null
                                          ? Image.network(img, fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.image, color: Color(0xFFCCCCCC))))
                                          : const Center(child: Icon(Icons.inventory_2_outlined, color: Color(0xFFCCCCCC))),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name']?.toString() ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatPrice(price),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
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
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Đánh giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const Spacer(),
              if (_totalRatings > 0) ...[
                const Icon(Icons.star, color: Color(0xFFFFA726), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${_avgRating.toStringAsFixed(1)} ($_totalRatings)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có đánh giá nào cho sản phẩm này',
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            )
          else
            Column(
              children: _reviews.take(5).map(_reviewTile).toList(),
            ),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final customer = r['customer'];
    final name = (customer is Map ? customer['full_name']?.toString() : null) ?? 'Khách hàng';
    final comment = r['comment']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFF0EB),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFA726),
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 36),
              child: Text(comment, style: const TextStyle(color: Color(0xFF555555), fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFFFFF0EB) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? _kPrimary : const Color(0xFFCCCCCC)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng cộng', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              Text(
                _formatPrice(_price * _quantity),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _onAddToCart,
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: const Text('Thêm vào giỏ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddToCart() {
    context.read<CartCubit>().addItem(
      productId: widget.productId,
      name: _product!['name'] as String? ?? '',
      price: _price,
      quantity: _quantity,
      thumbnail: _product!['thumbnail'] as String? ?? (() {
        final images = _product!['images'];
        if (images is List && images.isNotEmpty) {
          final primary = images.firstWhere(
            (img) => img['is_primary'] == true,
            orElse: () => images.first,
          );
          return primary['thumbnail_url'] as String? ?? primary['url'] as String?;
        }
        return null;
      })(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm $_quantity ${_product!['name']} vào giỏ!'),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              context.push('/cart');
            }
          },
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}
