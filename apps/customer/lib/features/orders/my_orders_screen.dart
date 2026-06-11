import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';
import '../../shared/layout/customer_responsive.dart';
import '../../shared/widgets/skeleton.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<CustomerAuthCubit>();
      final api = auth.api;
      final profile = await auth.fetchMyProfile();
      final customerId = profile?['id']?.toString();

      final response = await api.get(
        '/orders',
        queryParams: {
          if (customerId != null && customerId.isNotEmpty)
            'customer_id': customerId,
        },
      );

      if (!mounted) return;

      final wrapper =
          response.data is Map ? (response.data as Map)['data'] : null;
      final data = wrapper is Map ? wrapper['data'] : wrapper;

      setState(() {
        _orders = data is List
            ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _markOrderCancelledLocally(String orderId) {
    final index = _orders.indexWhere((o) => o['id']?.toString() == orderId);
    if (index == -1) return;

    final updated = Map<String, dynamic>.from(_orders[index]);
    updated['status'] = 'cancelled';

    setState(() {
      _orders[index] = updated;
    });
  }

  List<Map<String, dynamic>> _filterByStatus(String? status) {
    if (status == null) return _orders;

    return _orders.where((o) {
      final currentStatus = o['status']?.toString().trim().toLowerCase();
      final targetStatus = status.trim().toLowerCase();
      return currentStatus == targetStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const OrderCardSkeleton(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              OmnigoButton(
                label: 'Thử lại',
                onPressed: _loadOrders,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: _kBg,
          padding: CustomerResponsive.headerPadding(context, bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đơn hàng của tôi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                labelColor: _kPrimary,
                unselectedLabelColor: const Color(0xFF888888),
                indicatorColor: _kPrimary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: 'Đang xử lý'),
                  Tab(text: 'Hoàn thành'),
                  Tab(text: 'Đã hủy'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: [
                  ..._filterByStatus('draft'),
                  ..._filterByStatus('confirmed'),
                  ..._filterByStatus('processing'),
                  ..._filterByStatus('pending'),
                  ..._filterByStatus('shipping'),
                ],
                onRefresh: _loadOrders,
                onOrderCancelled: _markOrderCancelledLocally,
              ),
              _OrderList(
                orders: _filterByStatus('completed'),
                onRefresh: _loadOrders,
                onOrderCancelled: _markOrderCancelledLocally,
              ),
              _OrderList(
                orders: _filterByStatus('cancelled'),
                onRefresh: _loadOrders,
                onOrderCancelled: _markOrderCancelledLocally,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Future<void> Function() onRefresh;
  final void Function(String orderId) onOrderCancelled;

  const _OrderList({
    required this.orders,
    required this.onRefresh,
    required this.onOrderCancelled,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có đơn hàng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.go('/products'),
                    child: const Text(
                      'Mua sắm ngay >',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          onRefreshNeeded: onRefresh,
          onOrderCancelled: onOrderCancelled,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function() onRefreshNeeded;
  final void Function(String orderId) onOrderCancelled;

  const _OrderCard({
    required this.order,
    required this.onRefreshNeeded,
    required this.onOrderCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final (statusColor, statusText, statusIcon) = _statusInfo(status);
    final items = order['items'] as List? ?? [];

    final orderId = order['id']?.toString() ?? '';
    final orderNumber = order['order_number']?.toString();
    final shortOrderId =
        orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final displayOrderNumber =
        (orderNumber != null && orderNumber.isNotEmpty)
            ? orderNumber
            : shortOrderId;

    final canReorder = status == 'completed';
    final canCancel = status == 'pending' ||
        status == 'processing' ||
        status == 'draft' ||
        status == 'confirmed' ||
        status == 'shipping';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: orderId.isEmpty
                  ? null
                  : () => context.push('/order/$orderId'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$displayOrderNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${items.length} sản phẩm',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _formatDate(order['created_at']),
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatCurrency(order['total_amount']),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (canReorder || canCancel) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  if (canReorder)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: _kPrimary,
                        ),
                        label: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _reorder(context, order),
                      ),
                    ),
                  if (canReorder && canCancel) const SizedBox(height: 10),
                  if (canCancel)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE57373)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: orderId.isEmpty
                            ? null
                            : () => _cancelOrder(context, orderId),
                        child: const Text(
                          'Hủy đơn hàng',
                          style: TextStyle(
                            color: Color(0xFFE57373),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
        return (OmnigoColors.info, 'Đang giao', Icons.local_shipping);
      case 'cancelled':
        return (OmnigoColors.error, 'Đã hủy', Icons.cancel);
      case 'draft':
        return (Colors.purple, 'Chờ thanh toán', Icons.qr_code_scanner);
      default:
        return (Colors.grey, 'Chờ xác nhận', Icons.schedule);
    }
  }

  void _reorder(BuildContext context, Map<String, dynamic> order) {
    final items = order['items'] as List? ?? [];
    final cart = context.read<CartCubit>();

    for (final item in items) {
      final m = item as Map<String, dynamic>;
      final int qty = (m['quantity'] as num?)?.toInt() ?? 1;

      cart.addItem(
        productId: m['product_id'] as String? ?? '',
        name: m['product_name'] as String? ?? 'Sản phẩm',
        price: (m['unit_price'] as num?)?.toDouble() ?? 0,
        quantity: qty,
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

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<CustomerAuthCubit>().api;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Không',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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

    if (confirm != true || !context.mounted) return;

    try {
      await api.put('/orders/$orderId/cancel', data: {});

      onOrderCancelled(orderId);

      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đơn hàng'),
          backgroundColor: Colors.orange,
        ),
      );

      Future.microtask(() async {
        try {
          await onRefreshNeeded();
        } catch (_) {}
      });
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể hủy đơn hàng: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
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