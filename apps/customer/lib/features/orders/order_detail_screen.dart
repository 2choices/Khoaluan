import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;
  final Map<String, Map<String, dynamic>> _reviewsByProduct = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = context.read<CustomerAuthCubit>().api;
      final response = await api.get('/orders/${widget.orderId}');
      final payload = _unwrapData(response.data);

      if (!mounted) return;

      setState(() {
        _order = payload is Map ? Map<String, dynamic>.from(payload) : null;
        _loading = false;
      });

      await _loadReviews();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get<dynamic>('/reviews/order/${widget.orderId}');
      final raw = _unwrapData(res.data);
      final list = raw is List ? raw : [];

      _reviewsByProduct.clear();

      for (final r in list) {
        if (r is Map) {
          final pid = r['product_id']?.toString();
          if (pid != null) {
            _reviewsByProduct[pid] = Map<String, dynamic>.from(r);
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final lvl1 = raw['data'];
      if (lvl1 is Map && lvl1['data'] != null) {
        return lvl1['data'];
      }
      return lvl1;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final titleOrderNumber = _buildDisplayOrderNumber(
      orderNumber: _order?['order_number'],
      orderId: widget.orderId,
    );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        ),
        title: Text(
          'Đơn #$titleOrderNumber',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: OmnigoLoading())
          : _error != null
              ? _buildError()
              : _order == null
                  ? const Center(child: Text('Không tìm thấy đơn hàng'))
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'Không thể tải đơn hàng',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          OmnigoButton(
            label: 'Thử lại',
            onPressed: _loadOrder,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final status = order['status']?.toString() ?? 'pending';
    final items = order['items'] as List? ?? [];
    final (statusColor, statusText, statusIcon) = _statusInfo(status);

    final displayOrderNumber = _buildDisplayOrderNumber(
      orderNumber: order['order_number'],
      orderId: order['id'],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        _statusDescription(status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _sectionCard(
            title: 'Thông tin đơn hàng',
            child: Column(
              children: [
                _infoRow('Mã đơn', '#$displayOrderNumber'),
                _infoRow('Ngày đặt', _formatDate(order['created_at'])),
                _infoRow('Phương thức TT', _paymentLabel(order['payment_method'])),
                if (order['note'] != null &&
                    order['note'].toString().isNotEmpty)
                  _infoRow('Ghi chú', order['note'].toString()),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (order['shipping_address'] != null)
            _sectionCard(
              title: 'Địa chỉ giao hàng',
              child: Column(
                children: [
                  if (order['shipping_name'] != null)
                    _infoRow('Người nhận', order['shipping_name'].toString()),
                  if (order['shipping_phone'] != null)
                    _infoRow('Điện thoại', order['shipping_phone'].toString()),
                  _infoRow('Địa chỉ', order['shipping_address'].toString()),
                ],
              ),
            ),
          if (order['shipping_address'] != null) const SizedBox(height: 12),

          _sectionCard(
            title: 'Sản phẩm (${items.length})',
            child: Column(
              children: [
                ...items.map(
                  (item) => _itemRow(Map<String, dynamic>.from(item as Map)),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _formatCurrency(order['total_amount']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (status == 'completed')
            OmnigoButton(
              label: 'Đặt lại đơn hàng',
              expanded: true,
              size: OmnigoButtonSize.large,
              onPressed: () => _reorder(items),
            ),

          if (status == 'pending' ||
              status == 'processing' ||
              status == 'draft' ||
              status == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE57373)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _cancelOrder(order['id']),
                child: const Text(
                  'Hủy đơn hàng',
                  style: TextStyle(
                    color: Color(0xFFE57373),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _itemRow(Map<String, dynamic> item) {
    final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final int qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final productId = item['product_id']?.toString();
    final status = _order?['status']?.toString();
    final canReview = productId != null && status == 'completed';
    final review = productId != null ? _reviewsByProduct[productId] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFFCCCCCC),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name']?.toString() ?? 'Sản phẩm',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatCurrency(price)} × $qty',
                      style: const TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(price * qty),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (canReview) ...[
            const SizedBox(height: 6),
            if (review != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ...List.generate(5, (i) {
                    final filled = i < ((review['rating'] as num?)?.toInt() ?? 0);
                    return Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFA726),
                      size: 14,
                    );
                  }),
                  const SizedBox(width: 6),
                  const Text(
                    'Đã đánh giá',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openReviewDialog(item),
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    size: 16,
                    color: _kPrimary,
                  ),
                  label: const Text(
                    'Đánh giá',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openReviewDialog(Map<String, dynamic> item) async {
    final productId = item['product_id']?.toString();
    if (productId == null) return;

    int rating = 5;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Đánh giá: ${item['product_name'] ?? 'Sản phẩm'}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < rating;
                    return IconButton(
                      onPressed: submitting
                          ? null
                          : () => setLocal(() => rating = i + 1),
                      icon: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFA726),
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Cảm nhận của bạn (tuỳ chọn)',
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: submitting
                  ? null
                  : () async {
                      setLocal(() => submitting = true);
                      try {
                        final api = context.read<CustomerAuthCubit>().api;
                        await api.post<dynamic>('/reviews', data: {
                          'product_id': productId,
                          'order_id': widget.orderId,
                          'rating': rating,
                          'comment': commentCtrl.text.trim(),
                        });

                        if (!mounted) return;
                        Navigator.of(dialogCtx).pop();

                        await _loadReviews();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cảm ơn bạn đã đánh giá!'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      } catch (e) {
                        setLocal(() => submitting = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gửi đánh giá lỗi: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text(submitting ? 'Đang gửi...' : 'Gửi'),
            ),
          ],
        ),
      ),
    );

    commentCtrl.dispose();
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reorder(List items) {
    final cart = context.read<CartCubit>();

    for (final item in items) {
      final m = item as Map<String, dynamic>;
      final int itemQty = (m['quantity'] as num?)?.toInt() ?? 1;

      cart.addItem(
        productId: m['product_id'] as String? ?? '',
        name: m['product_name'] as String? ?? 'Sản phẩm',
        price: (m['unit_price'] as num?)?.toDouble() ?? 0,
        quantity: itemQty,
        thumbnail: m['thumbnail'] as String?,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã thêm vào giỏ hàng'),
        backgroundColor: OmnigoColors.success,
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(dynamic orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Không',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(
                color: Color(0xFFE57373),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.put('/orders/$orderId/status', data: {'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn hàng'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadOrder();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể hủy đơn hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  (Color, String, IconData) _statusInfo(String status) {
    switch (status) {
      case 'completed':
        return (OmnigoColors.success, 'Hoàn thành', Icons.check_circle);
      case 'confirmed':
        return (OmnigoColors.success, 'Đã xác nhận', Icons.verified);
      case 'processing':
        return (OmnigoColors.warning, 'Đang xử lý', Icons.hourglass_top);
      case 'shipping':
        return (OmnigoColors.info, 'Đang giao hàng', Icons.local_shipping);
      case 'cancelled':
        return (OmnigoColors.error, 'Đã hủy', Icons.cancel);
      case 'draft':
        return (Colors.purple, 'Chờ thanh toán', Icons.qr_code_scanner);
      default:
        return (Colors.grey, 'Chờ xác nhận', Icons.schedule);
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'completed':
        return 'Đơn hàng đã giao thành công';
      case 'confirmed':
        return 'Đơn hàng đã được duyệt thành công';
      case 'processing':
        return 'Đang chuẩn bị hàng cho bạn';
      case 'shipping':
        return 'Shipper đang trên đường giao';
      case 'cancelled':
        return 'Đơn hàng đã bị hủy';
      case 'draft':
        return 'Vui lòng hoàn tất quét mã QR thanh toán trên POS';
      default:
        return 'Đang chờ xác nhận từ cửa hàng';
    }
  }

  String _paymentLabel(dynamic method) {
    if (method == null || method.toString().isEmpty) {
      final payments = _order?['payments'];
      if (payments is List && payments.isNotEmpty) {
        final first = payments.first;
        if (first is Map && first['method'] != null) {
          method = first['method'];
        }
      }
    }

    switch (method?.toString()) {
      case 'cash':
        return 'Tiền mặt khi nhận hàng';
      case 'bank':
        return 'Chuyển khoản ngân hàng (VietQR)';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'payos':
        return 'Cổng thanh toán điện tử PayOS';
      default:
        return method?.toString() ?? '---';
    }
  }

  String _buildDisplayOrderNumber({
    required dynamic orderNumber,
    required dynamic orderId,
  }) {
    final orderNumberText = orderNumber?.toString();
    if (orderNumberText != null && orderNumberText.isNotEmpty) {
      return orderNumberText;
    }

    final orderIdText = orderId?.toString() ?? '';
    if (orderIdText.length > 8) {
      return orderIdText.substring(0, 8);
    }
    return orderIdText;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatCurrency(dynamic value) {
    num amount = 0;
    if (value is num) {
      amount = value;
    } else if (value != null) {
      amount = num.tryParse(value.toString()) ?? 0;
    }

    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }
}