import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/customers');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          final customerList = data is Map ? data['data'] : data;
          _customers = customerList is List
              ? customerList.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _customers;
    return _customers.where((c) {
      final name = (c['full_name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString();
      return name.contains(_search.toLowerCase()) || phone.contains(_search);
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
              final title = Text(
                'Khách hàng',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
              final search = OmnigoTextField(
                hint: 'Tìm khách hàng...',
                prefixIcon: Icons.search,
                onChanged: (v) => setState(() => _search = v),
              );

              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), search],
                );
              }

              return Row(children: [title, const Spacer(), SizedBox(width: 300, child: search)]);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _filtered.isEmpty
                    ? const Center(child: Text('Không có khách hàng nào'))
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

  Widget _buildMobileList() {
    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = _filtered[i];
        final name = '${c['full_name'] ?? '?'}';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: OmnigoColors.primary.withValues(alpha: 0.1),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(color: OmnigoColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    if (c['phone'] != null)
                      Text('${c['phone']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    if (c['email'] != null)
                      Text('${c['email']}', style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${c['total_orders'] ?? 0} đơn',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(_formatCurrency(c['total_spent']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: OmnigoColors.primary)),
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
            DataColumn(label: Text('Tên')),
            DataColumn(label: Text('Điện thoại')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Tổng đơn'), numeric: true),
            DataColumn(label: Text('Tổng chi'), numeric: true),
          ],
          rows: _filtered.map((c) {
            return DataRow(cells: [
              DataCell(Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: OmnigoColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      (c['full_name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: OmnigoColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${c['full_name'] ?? ''}'),
                ],
              )),
              DataCell(Text('${c['phone'] ?? '-'}')),
              DataCell(Text('${c['email'] ?? '-'}')),
              DataCell(Text('${c['total_orders'] ?? 0}')),
              DataCell(Text(_formatCurrency(c['total_spent']))),
            ]);
          }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num amount = (value is num) ? value : 0;
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }
}
