import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _revenueData = {};
  Map<String, dynamic> _productData = {};
  Map<String, dynamic> _customerData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    try {
      final api = context.read<AuthCubit>().api;
      final startDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final endDate = DateTime.now().toIso8601String();
      final responses = await Future.wait([
        api.get('/reports/revenue', queryParams: {
          'groupBy': 'day',
          'startDate': startDate,
          'endDate': endDate,
        }),
        api.get('/reports/products', queryParams: {
          'limit': 20,
          'startDate': startDate,
          'endDate': endDate,
        }),
        api.get('/reports/customers', queryParams: {
          'startDate': startDate,
          'endDate': endDate,
        }),
      ]);
      if (mounted) {
        setState(() {
          _revenueData = _unwrapData(responses[0].data);
          _productData = _unwrapData(responses[1].data);
          _customerData = _unwrapData(responses[2].data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: OmnigoColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: OmnigoColors.primary,
            tabs: const [
              Tab(text: 'Doanh thu'),
              Tab(text: 'Sản phẩm'),
              Tab(text: 'Khách hàng'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRevenueTab(),
                      _buildProductsTab(),
                      _buildCustomersTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    final summary = _revenueData['summary'];
    return SingleChildScrollView(
      child: Column(
        children: [
          _metricRow([
            _Metric('Tổng doanh thu', _formatCurrency(summary?['totalRevenue']), OmnigoColors.success),
            _Metric('Tổng đơn hàng', '${summary?['orderCount'] ?? summary?['totalOrders'] ?? 0}', OmnigoColors.primary),
            _Metric('TB/đơn hàng', _formatCurrency(summary?['averageOrderValue']), OmnigoColors.warning),
          ]),
          const SizedBox(height: 24),
          OmnigoCard(
            title: 'Biểu đồ doanh thu 30 ngày',
            child: _buildRevenueBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final products = (_productData['products'] as List?) ?? [];
    if (products.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu sản phẩm trong kỳ'));
    }

    return SingleChildScrollView(
      child: OmnigoCard(
        title: 'Báo cáo sản phẩm',
        child: Column(
          children: products.take(20).map<Widget>((item) {
            final product = item as Map;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: OmnigoColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.inventory_2, color: OmnigoColors.primary),
              ),
              title: Text('${product['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${product['quantity'] ?? 0} sản phẩm đã bán'),
              trailing: Text(
                _formatCurrency(product['revenue']),
                style: const TextStyle(fontWeight: FontWeight.bold, color: OmnigoColors.primary),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      child: _metricRow([
        _Metric('Khách hàng mới', '${_customerData['newCustomers'] ?? 0}', OmnigoColors.primary),
        _Metric('Khách có đơn', '${_customerData['activeCustomers'] ?? 0}', OmnigoColors.success),
        _Metric('Tổng đơn trong kỳ', '${_customerData['totalOrders'] ?? 0}', OmnigoColors.warning),
      ]),
    );
  }

  Widget _metricRow(List<_Metric> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map((metric) => SizedBox(
                      width: constraints.maxWidth < 420 ? constraints.maxWidth : (constraints.maxWidth - 12) / 2,
                      child: _metricCard(metric),
                    ))
                .toList(),
          );
        }

        return Row(
          children: metrics
              .map((metric) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _metricCard(metric),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(_Metric metric) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metric.label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: metric.color),
            ),
          ],
        ),
    );
  }

  Widget _buildRevenueBars() {
    final details = (_revenueData['details'] as List?) ?? [];
    if (details.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Chưa có dữ liệu doanh thu trong kỳ')),
      );
    }

    final maxRevenue = details.fold<num>(0, (max, item) {
      final value = item is Map && item['revenue'] is num ? item['revenue'] as num : 0;
      return value > max ? value : max;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: details.take(14).map<Widget>((item) {
          final row = item as Map;
          final revenue = row['revenue'] is num ? row['revenue'] as num : 0;
          final percent = maxRevenue == 0 ? 0.0 : (revenue / maxRevenue).clamp(0.0, 1.0).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 88, child: Text('${row['period'] ?? ''}', style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 10,
                      backgroundColor: OmnigoColors.primaryLight.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(OmnigoColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: Text(_formatCurrency(revenue), textAlign: TextAlign.right)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _unwrapData(dynamic responseData) {
    if (responseData is! Map) return {};
    final data = responseData['data'];
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  String _formatCurrency(dynamic value) {
    final num amount = (value is num) ? value : 0;
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K đ';
    return '${amount.toInt()} đ';
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}
