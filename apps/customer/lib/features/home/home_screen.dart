import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../ai/ai_cubit.dart';
import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';
import '../notifications/notification_badge_cubit.dart';
import '../../shared/layout/customer_responsive.dart';
import '../../shared/widgets/skeleton.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

// Icon mapping cho từng danh mục
const _kCategoryIcons = <String, IconData>{
  'thời trang': Icons.checkroom_outlined,
  'đồ uống': Icons.local_cafe_outlined,
  'phụ kiện': Icons.watch_outlined,
  'thực phẩm': Icons.lunch_dining_outlined,
  'điện tử': Icons.devices_outlined,
  'giày dép': Icons.ice_skating_outlined,
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _featured = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      if (mounted) {
        context.read<NotificationBadgeCubit>().startAutoRefresh();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final user = context.read<CustomerAuthCubit>().state.user;
      final prodRes = await api.get(
        '/catalog/products',
        queryParams: {'limit': '8'},
      );
      final prodWrapper = prodRes.data?['data'];
      final prodData = prodWrapper is Map ? prodWrapper['data'] : prodWrapper;

      List<Map<String, dynamic>> cats = [];
      try {
        final catRes = await api.get('/catalog/categories');
        final catData = catRes.data?['data']?['data'] ?? catRes.data?['data'];
        cats = catData is List
            ? catData.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      } catch (_) {}

      if (mounted) {
        setState(() {
          _featured = prodData is List
              ? prodData
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : [];
          _categories = cats;
          _loading = false;
        });
        // Load AI recommendations sau khi data chính đã xong
        context.read<AiCubit>().loadRecommendations(
          customerId: user?.id,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được dữ liệu, kéo xuống để thử lại'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<CustomerAuthCubit>().state.user;
    final name = user?.userMetadata?['full_name'] as String? ?? 'bạn';
    final firstName = name.split(' ').last;

    return BlocListener<CustomerAuthCubit, CustomerAuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.status == CustomerAuthStatus.authenticated,
      listener: (_, _) => _loadData(),
      child: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: _kBg,
              foregroundColor: const Color(0xFF1A1A1A),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 20,
              toolbarHeight: 60,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Xin chào 👋',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF1A1A1A),
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                    BlocBuilder<NotificationBadgeCubit, NotificationBadgeState>(
                      builder: (context, st) {
                        if (st.unread <= 0) return const SizedBox.shrink();
                        final label = st.unread > 99 ? '99+' : '${st.unread}';
                        return Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, cartState) => Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF1A1A1A),
                        ),
                        onPressed: () => context.push('/cart'),
                      ),
                      if (cartState.totalQuantity > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartState.totalQuantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ── Loading skeleton ─────────────────────────────
            if (_loading)
              SliverFillRemaining(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SkeletonBox(height: 48, radius: 12),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SkeletonBox(height: 160, radius: 20),
                      ),
                      const ProductGridSkeleton(count: 4),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Search bar ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFBBBBBB),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Tìm kiếm sản phẩm...',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE5E5E5),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFFBBBBBB),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Promo banner ─────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  height: 160,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 30,
                        bottom: -40,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                      // Tag icon
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Icon(
                          Icons.local_offer_rounded,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      // Text content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 120, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '🎉  ƯU ĐÃI ĐỘC QUYỀN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Giảm 30%\nđơn đầu tiên',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Dùng ngay →',
                                    style: TextStyle(
                                      color: _kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Categories ───────────────────────────────────
              if (_categories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh mục',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/products'),
                          child: const Text(
                            'Tất cả',
                            style: TextStyle(
                              color: _kPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final catName = (cat['name'] ?? '') as String;
                        final icon =
                            _kCategoryIcons[catName.toLowerCase()] ??
                            Icons.grid_view_rounded;
                        return GestureDetector(
                          onTap: () => context.go('/products'),
                          child: Column(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDE6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(icon, color: _kPrimary, size: 26),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 62,
                                child: Text(
                                  catName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ── Featured header ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nổi bật hôm nay',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/products'),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: _kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Product grid ─────────────────────────────────
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = CustomerResponsive.productColumns(
                    constraints.crossAxisExtent,
                  );
                  final aspectRatio = CustomerResponsive.productAspectRatio(
                    constraints.crossAxisExtent,
                  );
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: _featured.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Chưa có sản phẩm',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: aspectRatio,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _productCard(_featured[i]),
                              childCount: _featured.length,
                            ),
                          ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── AI Recommendations ───────────────────────────
              BlocBuilder<AiCubit, AiState>(
                builder: (context, aiState) {
                  if (aiState.loadingRec) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: SkeletonBox(height: 180, radius: 12),
                      ),
                    );
                  }
                  if (aiState.recommendations.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 18, color: _kPrimary),
                              const SizedBox(width: 6),
                              const Text(
                                'Gợi ý cho bạn',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.go('/products'),
                                child: const Text(
                                  'Xem tất cả',
                                  style: TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: aiState.recommendations.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _aiProductCard(context, aiState.recommendations[i]),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _aiProductCard(BuildContext context, Map<String, dynamic> product) {
    final price =
        (product['base_price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0;
    String? thumbnailUrl = product['thumbnail'] as String?;
    if (thumbnailUrl == null) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        thumbnailUrl = images.first['thumbnail_url'] as String? ?? images.first['url'] as String?;
      }
    }
    return GestureDetector(
      onTap: () => context.go('/product/${product['id']}'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: thumbnailUrl != null
                    ? Image.network(thumbnailUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: const Color(0xFFF5F5F5),
                            child: const Center(child: Icon(Icons.image, size: 32, color: Color(0xFFCCCCCC)))))
                    : Container(color: const Color(0xFFF5F5F5),
                        child: const Center(child: Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFFCCCCCC)))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(price),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final price =
        (product['base_price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0;
    final comparePrice = (product['compare_price'] as num?)?.toDouble();
    final hasDiscount = comparePrice != null && comparePrice > price;

    String? thumbnailUrl = product['thumbnail'] as String?;
    if (thumbnailUrl == null) {
      final images = product['images'];
      if (images is List && images.isNotEmpty) {
        final primary = images.firstWhere(
          (img) => img['is_primary'] == true,
          orElse: () => images.first,
        );
        thumbnailUrl =
            primary['thumbnail_url'] as String? ?? primary['url'] as String?;
      }
    }

    return GestureDetector(
      onTap: () => context.go('/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            final isTight = cardConstraints.maxWidth < 145;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use Expanded so image area adapts to grid cell height and avoids overflow.
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: thumbnailUrl != null
                              ? Image.network(
                                  thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 32,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Center(
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 36,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${((1 - price / comparePrice) * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: () {
                            context.read<CartCubit>().addItem(
                              productId: product['id'] as String? ?? '',
                              name: product['name'] as String? ?? '',
                              price: price,
                              thumbnail: thumbnailUrl,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm ${product['name']} vào giỏ!',
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(10, 8, 10, isTight ? 8 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product['name'] ?? '',
                        maxLines: isTight ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTight ? 11.5 : 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: isTight ? 3 : 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatPrice(price),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: isTight ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                      if (hasDiscount)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatPrice(comparePrice),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFAAAAAA),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}
