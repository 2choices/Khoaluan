import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/products');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          final productList = data is Map ? data['data'] : data;
          _products = productList is List
              ? productList
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được danh sách sản phẩm'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_search.isEmpty) return _products;
    return _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(_search.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final title = Text(
                'Sản phẩm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
              final search = OmnigoTextField(
                hint: 'Tìm sản phẩm...',
                prefixIcon: Icons.search,
                onChanged: (v) => setState(() => _search = v),
              );
              final action = OmnigoButton(
                label: 'Thêm sản phẩm',
                prefixIcon: Icons.add,
                onPressed: () => _showProductDialog(),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    search,
                    const SizedBox(height: 12),
                    action,
                  ],
                );
              }

              return Row(
                children: [
                  title,
                  const Spacer(),
                  SizedBox(width: 300, child: search),
                  const SizedBox(width: 12),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('Không có sản phẩm nào'))
                    : LayoutBuilder(
                        builder: (_, c) => c.maxWidth < OmnigoBreakpoints.compact
                            ? _buildMobileList()
                            : _buildProductTable(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _filteredProducts[i];
        final active = p['is_active'] == true;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OmnigoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _thumbnailOf(p) != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _thumbnailOf(p)!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image,
                            size: 20,
                            color: OmnigoColors.primary,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        size: 20,
                        color: OmnigoColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['name'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p['sku'] ?? '—'}  ·  ${_formatPrice(_priceOf(p))}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tồn: ${p['stock_quantity'] ?? p['inventory_quantity'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatus(active),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showProductDialog(product: p),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: OmnigoColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _deleteProduct(p),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(OmnigoColors.surfaceWarm),
            columnSpacing: 28,
            columns: const [
              DataColumn(label: Text('Tên sản phẩm')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Giá'), numeric: true),
              DataColumn(label: Text('Tồn kho'), numeric: true),
              DataColumn(label: Text('Trạng thái')),
              DataColumn(label: Text('')),
            ],
            rows: _filteredProducts.map((p) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: OmnigoColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _thumbnailOf(p) != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _thumbnailOf(p)!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.image,
                                      size: 20,
                                      color: OmnigoColors.primary,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2,
                                  size: 20,
                                  color: OmnigoColors.primary,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${p['name'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('${p['sku'] ?? '-'}')),
                  DataCell(Text(_formatPrice(_priceOf(p)))),
                  DataCell(
                    Text(
                      '${p['stock_quantity'] ?? p['inventory_quantity'] ?? 0}',
                    ),
                  ),
                  DataCell(_buildStatus(p['is_active'] == true)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showProductDialog(product: p),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteProduct(p),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? OmnigoColors.success.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Đang bán' : 'Ẩn',
        style: TextStyle(
          fontSize: 12,
          color: active ? OmnigoColors.success : Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _priceOf(Map<String, dynamic> product) {
    return (product['base_price'] as num?)?.toDouble() ??
        (product['price'] as num?)?.toDouble() ??
        0;
  }

  String? _thumbnailOf(Map<String, dynamic> product) {
    String? pick(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        final v = value.trim();
        if (v.startsWith('http://') || v.startsWith('https://')) {
          return v;
        }
      }
      return null;
    }

    final candidates = <String?>[
      pick(product['thumbnail']),
      pick(product['thumbnail_url']),
      pick(product['image']),
      pick(product['image_url']),
      pick(product['photo']),
      pick(product['photo_url']),
    ];

    final images = product['images'];
    if (images is List) {
      for (final item in images) {
        if (item is Map) {
          candidates.addAll([
            pick(item['thumbnail_url']),
            pick(item['url']),
            pick(item['image_url']),
            pick(item['image']),
            pick(item['photo_url']),
            pick(item['photo']),
          ]);
        } else {
          candidates.add(pick(item));
        }
      }
    }

    for (final c in candidates) {
      if (c != null) return c;
    }
    return null;
  }

  String _formatPrice(dynamic price) {
    final num p = price is num ? price : 0;
    return '${p.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  Future<Map<String, dynamic>?> _fetchProductDetail(String id) async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/products/$id');
      final data = response.data?['data'];
      final detail = data is Map ? (data['data'] ?? data) : data;
      if (detail is Map) {
        return Map<String, dynamic>.from(detail);
      }
      return null;
    } catch (e) {
      debugPrint('FETCH PRODUCT DETAIL ERROR: $e');
      return null;
    }
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: product == null ? '' : '${_priceOf(product)}',
    );
    final skuCtrl = TextEditingController(text: product?['sku'] ?? '');
    final imageCtrl = TextEditingController(
      text: _thumbnailOf(product ?? const <String, dynamic>{}) ?? '',
    );

    String normalizeImageUrl(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return '';

      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }

      if (value.startsWith('//')) {
        return 'https:$value';
      }

      if (value.startsWith('images.unsplash.com/')) {
        return 'https://$value';
      }

      if (value.contains('images.unsplash.com') && !value.startsWith('http')) {
        return 'https://$value';
      }

      return value;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) {
          final previewUrl = normalizeImageUrl(imageCtrl.text);

          return AlertDialog(
            title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
            content: SizedBox(
              width: (MediaQuery.sizeOf(dialogContext).width - 80).clamp(
                280.0,
                420.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OmnigoTextField(controller: nameCtrl, label: 'Tên sản phẩm'),
                    const SizedBox(height: 12),
                    OmnigoTextField(controller: skuCtrl, label: 'SKU'),
                    const SizedBox(height: 12),
                    OmnigoTextField(
                      controller: priceCtrl,
                      label: 'Giá',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    OmnigoTextField(
                      controller: imageCtrl,
                      label: 'URL ảnh',
                      onChanged: (_) => setLocalState(() {}),
                    ),
                    if (previewUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          previewUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 140,
                            width: double.infinity,
                            color: const Color(0xFFF5F5F5),
                            alignment: Alignment.center,
                            child: const Text(
                              'URL ảnh không hợp lệ',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
  final name = nameCtrl.text.trim();
  final priceText = priceCtrl.text
      .trim()
      .replaceAll('.', '')
      .replaceAll(',', '.');
  final price = double.tryParse(priceText) ?? 0;
  final imageUrl = normalizeImageUrl(imageCtrl.text);

  if (name.isEmpty || price <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng nhập tên và giá hợp lệ'),
      ),
    );
    return;
  }

  final payload = {
  'name': name,
  'sku': skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
  'base_price': price,
  'image_url': imageUrl.isEmpty ? null : imageUrl,
  'is_active': true,
};
                  try {
                    final api = context.read<AuthCubit>().api;

                    if (product == null) {
                      await api.post('/products', data: payload);
                    } else {
                      final productId = product['id']?.toString();

                      if (productId == null || productId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sản phẩm này thiếu id, chưa thể cập nhật'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final detail = await _fetchProductDetail(productId);
                      if (detail == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không lấy được chi tiết sản phẩm để cập nhật'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final realId = detail['id']?.toString() ?? productId;
                      await api.put('/products/$realId', data: payload);
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    await _loadProducts();
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Không thể lưu sản phẩm: $e'),
                        backgroundColor: OmnigoColors.error,
                      ),
                    );
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn chắc chắn muốn xóa "${product['name'] ?? ''}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final api = context.read<AuthCubit>().api;
      await api.delete('/products/${product['id']}');
      await _loadProducts();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa sản phẩm'),
          backgroundColor: OmnigoColors.error,
        ),
      );
    }
  }
}