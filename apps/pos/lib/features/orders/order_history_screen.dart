import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final api = context.read<PosAuthCubit>().api;
      final response = await api.get('/orders');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          _orders = data is List
              ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pos'),
        ),
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: _loading
          ? const Center(child: OmnigoLoading())
          : _orders.isEmpty
              ? const Center(child: Text('Chưa có đơn hàng nào'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 700 ? 12.0 : 24.0;
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _orderCard(_orders[i]),
                    );
                  },
                ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    Color statusColor;
    String statusText;
    switch (status) {
      case 'completed':
        statusColor = OmnigoColors.success;
        statusText = 'Hoàn thành';
      case 'processing':
        statusColor = OmnigoColors.warning;
        statusText = 'Đang xử lý';
      case 'cancelled':
        statusColor = OmnigoColors.error;
        statusText = 'Đã hủy';
      default:
        statusColor = Colors.grey;
        statusText = 'Chờ xử lý';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final leading = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long, color: statusColor, size: 24),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order['order_number'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${order['customer_name'] ?? 'Khách lẻ'} • ${_formatDate(order['created_at'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
          final amount = Column(
            crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(order['total_amount']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [leading, const SizedBox(width: 12), Expanded(child: details)]),
                const SizedBox(height: 12),
                amount,
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(child: details),
              amount,
            ],
          );
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }

  String _formatCurrency(dynamic value) {
    final num amount = (value is num) ? value : 0;
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
  }
}
