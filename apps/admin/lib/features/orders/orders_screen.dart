import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _search = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      if (!mounted) return;
      setState(() => _loading = true);

      final api = context.read<AuthCubit>().api;
      final response = await api.get('/orders');
      final data = response.data?['data'];
      final orderList = data is Map ? data['data'] : data;

      if (!mounted) return;

      setState(() {
        _orders = orderList is List
            ? orderList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tải được danh sách đơn hàng. Kiểm tra kết nối mạng hoặc máy chủ.'),
          backgroundColor: OmnigoColors.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      final orderNumber =
          (order['order_number'] ?? '').toString().toLowerCase();
      final customerName =
          (order['customer_name'] ?? order['shipping_name'] ?? '')
              .toString()
              .toLowerCase();
      final matchesSearch = _search.isEmpty ||
          orderNumber.contains(_search.toLowerCase()) ||
          customerName.contains(_search.toLowerCase());

      final matchesStatus =
          _status == 'all' || (order['status']?.toString() == _status);

      return matchesSearch && matchesStatus;
    }).toList();
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
        )} đ';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'completed':
        return OmnigoColors.success;
      case 'cancelled':
        return OmnigoColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo mã đơn / khách hàng...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'draft', child: Text('Chờ xử lý')),
                    DropdownMenuItem(
                        value: 'confirmed', child: Text('Đã xác nhận')),
                    DropdownMenuItem(
                        value: 'processing', child: Text('Đang xử lý')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Hoàn thành')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'all'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _filteredOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng nào'))
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final order = _filteredOrders[index];
                            final orderId = order['id']?.toString() ?? '';
                            final orderNumber =
                                order['order_number']?.toString() ?? '-';
                            final customerName =
                                order['customer_name']?.toString() ??
                                    order['shipping_name']?.toString() ??
                                    'Khách lẻ';
                            final status = order['status']?.toString() ?? 'draft';
                            dynamic totalAmount = order['total_amount'];

                            return InkWell(
                              onTap: orderId.isEmpty
                                  ? null
                                  : () async {
                                      await context.push('/orders/$orderId');
                                      _loadOrders(); // Tự động reload sau khi thao tác bên trong chi tiết
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF0DDD2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#$orderNumber',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            customerName,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatCurrency(totalAmount),
                                            style: const TextStyle(
                                              color: OmnigoColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildStatusChip(status),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}