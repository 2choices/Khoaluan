import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  Map<String, dynamic>? _currentShift;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    try {
      final api = context.read<PosAuthCubit>().api;
      final response = await api.get('/shifts/current');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          _currentShift = data is Map ? Map<String, dynamic>.from(data) : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openShift() async {
    setState(() => _loading = true);
    try {
      final api = context.read<PosAuthCubit>().api;
      await api.post('/shifts/open', data: {
        'opening_amount': 0,
      });
      await _loadShift();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeShift() async {
    setState(() => _loading = true);
    try {
      final api = context.read<PosAuthCubit>().api;
      if (_currentShift != null) {
        await api.post('/shifts/${_currentShift!['id']}/close', data: {
          'closing_amount': 0,
        });
      }
      await _loadShift();
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
        title: const Text('Quản lý ca làm'),
      ),
      body: _loading
          ? const Center(child: OmnigoLoading())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: OmnigoBreakpoints.pagePadding(context),
                child: _currentShift != null ? _buildActiveShift() : _buildNoShift(),
              ),
            ),
    );
  }

  Widget _buildNoShift() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: OmnigoColors.warning.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule, size: 48, color: OmnigoColors.warning),
        ),
        const SizedBox(height: 24),
        Text(
          'Chưa mở ca',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Mở ca để bắt đầu bán hàng',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        OmnigoButton(
          label: 'Mở ca làm việc',
          prefixIcon: Icons.play_arrow,
          size: OmnigoButtonSize.large,
          onPressed: _openShift,
        ),
      ],
    );
  }

  Widget _buildActiveShift() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: OmnigoColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, size: 48, color: OmnigoColors.success),
        ),
        const SizedBox(height: 24),
        Text(
          'Ca đang mở',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: OmnigoColors.success,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              _infoRow('Bắt đầu', _formatTime(_currentShift?['opened_at'])),
              const Divider(height: 24),
              _infoRow('Số đơn', '${_currentShift?['order_count'] ?? 0}'),
              const Divider(height: 24),
              _infoRow('Doanh thu', _formatCurrency(_currentShift?['total_revenue'])),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OmnigoButton(
                label: 'Quay lại POS',
                variant: OmnigoButtonVariant.outline,
                prefixIcon: Icons.arrow_back,
                onPressed: () => context.go('/pos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OmnigoButton(
                label: 'Đóng ca',
                variant: OmnigoButtonVariant.primary,
                prefixIcon: Icons.stop,
                onPressed: _closeShift,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  String _formatTime(dynamic date) {
    if (date == null) return '-';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} - ${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '-';
    }
  }

  String _formatCurrency(dynamic value) {
    final num amount = (value is num) ? value : 0;
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }
}
