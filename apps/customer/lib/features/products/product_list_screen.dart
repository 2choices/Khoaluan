import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';
import '../../shared/layout/customer_responsive.dart';
import '../../shared/widgets/skeleton.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String _search = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final prodRes = await api.get(
        '/catalog/products',
        queryParams: {'limit': '50'},
      );
      final prodWrapper = prodRes.data?['data'];
      final prodData = prodWrapper is Map ? prodWrapper['data'] : prodWrapper;

      List<Map<String, dynamic>> cats = [];
      try {
        final catRes = await api.get('/catalog/categories');
        final catWrapper = catRes.data?['data'];
        final catData = catWrapper is Map ? catWrapper['data'] : catWrapper;
        cats = catData is List
            ? catData.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      } catch (_) {}

      if (mounted) {
        setState(() {
          _products = prodData is List
              ? prodData
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : [];
          _categories = cats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _products;
    if (_selectedCategoryId != null) {
      list = list.where((p) {
        final direct = p['category_id']?.toString();
        final category = p['category'];
        final nested = category is Map ? category['id']?.toString() : null;
        return direct == _selectedCategoryId || nested == _selectedCategoryId;
      }).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((p) => (p['name'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar cream
        Container(
          color: _kBg,
          padding: CustomerResponsive.headerPadding(context, bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_outlined, color: _kPrimary),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
        ),
        // Search bar
        Container(
          color: _kBg,
          padding: EdgeInsets.fromLTRB(
            CustomerResponsive.pagePadding(context).left,
            0,
            CustomerResponsive.pagePadding(context).right,
            8,
          ),
          child: OmnigoTextField(
            hint: 'Tìm kiếm sản phẩm...',
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        // Category chips
        if (_categories.isNotEmpty)
          Container(
            color: _kBg,
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final selected = _selectedCategoryId == null;
                  return FilterChip(
                    label: const Text('Tất cả'),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = null),
                    selectedColor: const Color(0xFFFFD5C2),
                    checkmarkColor: _kPrimary,
                    labelStyle: TextStyle(
                      color: selected ? _kPrimary : const Color(0xFF444444),
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? _kPrimary : const Color(0xFFBBBBBB),
                      width: selected ? 1.5 : 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }
                final cat = _categories[i - 1];
                final catId = cat['id']?.toString();
                final selected = _selectedCategoryId == catId;
                return FilterChip(
                  label: Text(cat['name'] ?? ''),
                  selected: selected,
                  onSelected: (_) => setState(
                    () => _selectedCategoryId = selected ? null : catId,
                  ),
                  selectedColor: const Color(0xFFFFD5C2),
                  checkmarkColor: _kPrimary,
                  labelStyle: TextStyle(
                    color: selected ? _kPrimary : const Color(0xFF444444),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? _kPrimary : const Color(0xFFBBBBBB),
                    width: selected ? 1.5 : 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
        if (_categories.isNotEmpty) const SizedBox(height: 8),
        // Results count
        if (!_loading)
          Container(
            color: _kBg,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} sản phẩm',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: CustomerResponsive.productColumns(
                          constraints.maxWidth,
                        ),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: CustomerResponsive.productAspectRatio(
                          constraints.maxWidth,
                        ),
                      ),
                      itemCount: 6,
                      itemBuilder: (_, _) => const ProductCardSkeleton(),
                    );
                  },
                )
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tìm thấy sản phẩm',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                      if (_search.isNotEmpty ||
                          _selectedCategoryId != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            _search = '';
                            _selectedCategoryId = null;
                          }),
                          child: const Text(
                            'Xóa bộ lọc',
                            style: TextStyle(color: _kPrimary),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _loadData,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: CustomerResponsive.productColumns(
                            constraints.maxWidth,
                          ),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio:
                              CustomerResponsive.productAspectRatio(
                                constraints.maxWidth,
                              ),
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _productCard(_filtered[i]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final price =
        (product['base_price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0;
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
      onTap: () => context.push('/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
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

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bộ lọc sản phẩm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text(
                      'Tất cả',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    selected: _selectedCategoryId == null,
                    selectedColor: const Color(0xFFC84B1A),
                    backgroundColor: const Color(0xFFF5F5F5),
                    labelStyle: TextStyle(
                      color: _selectedCategoryId == null ? Colors.white : const Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: _selectedCategoryId == null ? const Color(0xFFC84B1A) : const Color(0xFFDDDDDD),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = null);
                      Navigator.pop(context);
                    },
                  ),
                  ..._categories.map((category) {
                    final id = category['id']?.toString();
                    final isSelected = _selectedCategoryId == id;
                    return ChoiceChip(
                      label: Text(
                        category['name'] ?? '',
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFC84B1A),
                      backgroundColor: const Color(0xFFF5F5F5),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFC84B1A) : const Color(0xFFDDDDDD),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = id);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
