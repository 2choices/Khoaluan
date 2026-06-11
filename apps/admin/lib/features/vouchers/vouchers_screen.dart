import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/vouchers');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          final voucherList = data is Map ? data['data'] : data;
          _vouchers = voucherList is List
              ? voucherList
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
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
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Voucher',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
              final action = OmnigoButton(
                label: 'Tạo voucher',
                prefixIcon: Icons.add,
                onPressed: () => _showVoucherDialog(),
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), action],
                );
              }

              return Row(children: [title, const Spacer(), action]);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _vouchers.isEmpty
                ? const Center(child: Text('Chưa có voucher nào'))
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
      itemCount: _vouchers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final v = _vouchers[i];
        final isActive = v['status'] == 'active' || v['is_active'] == true;
        final type = v['type'] ?? v['discount_type'] ?? 'percentage';
        final value = v['value'] ?? v['discount_value'] ?? 0;
        final used = v['usage_count'] ?? v['used_count'] ?? 0;
        final limit = v['usage_limit'];
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
                  color: OmnigoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer, color: OmnigoColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${v['code'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(
                      type == 'percentage' ? 'Giảm $value%'
                          : type == 'fixed_amount' ? 'Giảm ${value}d'
                          : 'Miễn ship',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text('$used/${limit ?? '∞'} lượt  ·  HSD: ${_formatDate(v['end_date'] ?? v['ends_at'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? OmnigoColors.success.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Hoạt động' : 'Tắt',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? OmnigoColors.success : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              DataColumn(label: Text('Mã')),
              DataColumn(label: Text('Loại')),
              DataColumn(label: Text('Giá trị')),
              DataColumn(label: Text('Đã dùng'), numeric: true),
              DataColumn(label: Text('Hạn sử dụng')),
              DataColumn(label: Text('Trạng thái')),
            ],
            rows: _vouchers.map((v) {
              final isActive =
                  v['status'] == 'active' || v['is_active'] == true;
              final type = v['type'] ?? v['discount_type'] ?? 'percentage';
              final value = v['value'] ?? v['discount_value'] ?? 0;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${v['code'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      type == 'percentage'
                          ? 'Phần trăm'
                          : type == 'fixed_amount'
                          ? 'Cố định'
                          : 'Miễn ship',
                    ),
                  ),
                  DataCell(Text(type == 'percentage' ? '$value%' : '$valueđ')),
                  DataCell(
                    Text(
                      '${v['usage_count'] ?? v['used_count'] ?? 0}/${v['usage_limit'] ?? '∞'}',
                    ),
                  ),
                  DataCell(Text(_formatDate(v['end_date'] ?? v['ends_at']))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? OmnigoColors.success.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Tắt',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? OmnigoColors.success : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  String _formatDate(dynamic date) {
    if (date == null) return 'Không giới hạn';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '-';
    }
  }

  void _showVoucherDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo voucher mới'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(dialogContext).width - 80).clamp(
            280.0,
            400.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OmnigoTextField(controller: codeCtrl, label: 'Mã voucher'),
              const SizedBox(height: 12),
              OmnigoTextField(controller: nameCtrl, label: 'Tên voucher'),
              const SizedBox(height: 12),
              OmnigoTextField(
                controller: valueCtrl,
                label: 'Giá trị giảm (%)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              final value =
                  double.tryParse(valueCtrl.text.trim().replaceAll(',', '.')) ??
                  0;
              if (code.isEmpty || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập mã và giá trị hợp lệ'),
                  ),
                );
                return;
              }

              try {
                final api = context.read<AuthCubit>().api;
                final now = DateTime.now();
                await api.post(
                  '/vouchers',
                  data: {
                    'code': code,
                    'name': nameCtrl.text.trim().isEmpty
                        ? code
                        : nameCtrl.text.trim(),
                    'type': 'percentage',
                    'value': value,
                    'start_date': now.toIso8601String(),
                    'end_date': now
                        .add(const Duration(days: 30))
                        .toIso8601String(),
                  },
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadVouchers();
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể tạo voucher'),
                    backgroundColor: OmnigoColors.error,
                  ),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
