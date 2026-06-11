import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/dashboard/stats');
      if (mounted) {
        setState(() {
          _stats = response.data?['data'] is Map
              ? Map<String, dynamic>.from(response.data['data'])
              : {};
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được thống kê, vui lòng thử lại'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: OmnigoLoading(message: 'Đang tải...'));
    }

    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Chào mừng bạn quay trở lại!',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1000
                  ? 4
                  : constraints.maxWidth > 600
                  ? 2
                  : 1;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  StatCard(
                    title: 'Doanh thu hôm nay',
                    value: _formatCurrency(_stats['todayRevenue']),
                    icon: Icons.attach_money,
                    color: OmnigoColors.success,
                    trend: '+12%',
                  ),
                  StatCard(
                    title: 'Đơn hàng hôm nay',
                    value: '${_stats['todayOrders'] ?? 0}',
                    icon: Icons.receipt_long,
                    color: OmnigoColors.primary,
                    trend: '+5%',
                  ),
                  StatCard(
                    title: 'Khách hàng mới',
                    value: '${_stats['newCustomers'] ?? 0}',
                    icon: Icons.people,
                    color: OmnigoColors.warning,
                    trend: '+8%',
                  ),
                  StatCard(
                    title: 'Sản phẩm',
                    value: '${_stats['totalProducts'] ?? 0}',
                    icon: Icons.inventory_2,
                    color: OmnigoColors.secondary,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final recentOrders = OmnigoCard(
                title: 'Đơn hàng gần đây',
                child: _buildRecentOrders(),
              );
              final topProducts = OmnigoCard(
                title: 'Sản phẩm bán chạy',
                child: _buildTopProducts(),
              );

              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    recentOrders,
                    const SizedBox(height: 16),
                    topProducts,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: recentOrders),
                  const SizedBox(width: 16),
                  Expanded(child: topProducts),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final orders = (_stats['recentOrders'] as List?) ?? [];
    if (orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Chưa có đơn hàng nào')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(OmnigoColors.surfaceWarm),
        columnSpacing: 28,
        columns: const [
          DataColumn(label: Text('Mã ĐH')),
          DataColumn(label: Text('Khách hàng')),
          DataColumn(label: Text('Tổng tiền')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: orders.take(5).map<DataRow>((order) {
          final o = order as Map;
          return DataRow(
            cells: [
              DataCell(Text('#${o['order_number'] ?? ''}')),
              DataCell(Text('${o['customer_name'] ?? 'Khách lẻ'}')),
              DataCell(Text(_formatCurrency(o['total_amount']))),
              DataCell(_buildStatusChip('${o['status'] ?? 'pending'}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = (_stats['topProducts'] as List?) ?? [];
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Chưa có dữ liệu')),
      );
    }
    return Column(
      children: products.take(5).map<Widget>((p) {
        final product = p as Map;
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: OmnigoColors.primary.withValues(alpha: 0.1),
            child: const Icon(
              Icons.inventory_2,
              size: 16,
              color: OmnigoColors.primary,
            ),
          ),
          title: Text(
            '${product['name'] ?? ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${product['total_sold'] ?? 0} sold',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: OmnigoColors.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = OmnigoColors.success;
        label = 'Hoàn thành';
        break;
      case 'processing':
        color = OmnigoColors.warning;
        label = 'Đang xử lý';
        break;
      case 'cancelled':
        color = OmnigoColors.error;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = 'Chờ xử lý';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num amount = (value is num) ? value : 0;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '${amount.toInt()} đ';
  }
}
