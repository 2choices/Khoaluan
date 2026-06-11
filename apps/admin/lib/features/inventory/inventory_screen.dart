import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/inventory');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          final itemList = data is Map ? data['data'] : data;
          _items = itemList is List
              ? itemList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
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
    return Padding(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kho hàng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryCards(),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _items.isEmpty
                    ? const Center(child: Text('Chưa có dữ liệu kho'))
                    : LayoutBuilder(
                        builder: (_, c) => c.maxWidth < OmnigoBreakpoints.compact
                            ? _buildMobileList()
                            : _buildTable(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalItems = _items.length;
    final lowStock = _items.where((i) {
      final qty = (i['quantity'] ?? 0) as num;
      final min = (i['min_quantity'] ?? 10) as num;
      return qty <= min;
    }).length;
    final outOfStock = _items.where((i) => (i['quantity'] ?? 0) == 0).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _summaryCard('Tổng SP', '$totalItems', Icons.inventory_2, OmnigoColors.primary),
          _summaryCard('Sắp hết', '$lowStock', Icons.warning_amber, OmnigoColors.warning),
          _summaryCard('Hết hàng', '$outOfStock', Icons.error_outline, OmnigoColors.error),
        ];

        if (constraints.maxWidth < 720) {
          return Wrap(spacing: 12, runSpacing: 12, children: cards);
        }

        return Row(
          children: cards
              .map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: card)))
              .toList(),
        );
      },
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = _items[i];
        final qty = (item['quantity'] ?? 0) as num;
        final min = (item['min_quantity'] ?? 10) as num;
        String statusLabel;
        Color statusColor;
        if (qty == 0) {
          statusLabel = 'Hết hàng';
          statusColor = OmnigoColors.error;
        } else if (qty <= min) {
          statusLabel = 'Sắp hết';
          statusColor = OmnigoColors.warning;
        } else {
          statusLabel = 'Đủ hàng';
          statusColor = OmnigoColors.success;
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item['product_name'] ?? item['name'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('SKU: ${item['sku'] ?? '—'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  Text('Tồn: $qty / Tối thiểu: $min',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable() {
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
            DataColumn(label: Text('Sản phẩm')),
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Tồn kho'), numeric: true),
            DataColumn(label: Text('Tối thiểu'), numeric: true),
            DataColumn(label: Text('Trạng thái')),
          ],
          rows: _items.map((i) {
            final qty = (i['quantity'] ?? 0) as num;
            final min = (i['min_quantity'] ?? 10) as num;
            String status;
            Color color;
            if (qty == 0) {
              status = 'Hết hàng';
              color = OmnigoColors.error;
            } else if (qty <= min) {
              status = 'Sắp hết';
              color = OmnigoColors.warning;
            } else {
              status = 'Đủ hàng';
              color = OmnigoColors.success;
            }
            return DataRow(cells: [
              DataCell(Text('${i['product_name'] ?? i['name'] ?? ''}')),
              DataCell(Text('${i['sku'] ?? '-'}')),
              DataCell(Text('$qty')),
              DataCell(Text('$min')),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                ),
              )),
            ]);
          }).toList(),
          ),
        ),
      ),
    );
  }
}
