import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeCtrl = TextEditingController();

  bool _loading = true;
  bool _applying = false;
  String? _error;
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _expired = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get('/vouchers', queryParams: {'limit': 50});
      final wrapper = res.data?['data'];
      final list = wrapper is Map ? wrapper['data'] : wrapper;
      final now = DateTime.now();
      final available = <Map<String, dynamic>>[];
      final expired = <Map<String, dynamic>>[];
      if (list is List) {
        for (final raw in list) {
          if (raw is! Map) continue;
          final v = Map<String, dynamic>.from(raw);
          DateTime? endDate;
          final endRaw = v['end_date'];
          if (endRaw is String) {
            endDate = DateTime.tryParse(endRaw);
          }
          final isActive = v['is_active'] != false;
          final isExpired = endDate != null && endDate.isBefore(now);
          if (isActive && !isExpired) {
            available.add(v);
          } else {
            expired.add(v);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _available = available;
        _expired = expired;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được danh sách voucher';
      });
    }
  }

  Future<void> _applyCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _applying = true);
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.post(
        '/vouchers/validate',
        data: {'code': code, 'orderAmount': 0},
      );
      final data = res.data?['data'];
      final valid = data is Map ? data['valid'] == true : false;
      if (!mounted) return;
      if (valid) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Mã "$code" hợp lệ. Áp dụng khi thanh toán.'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        _codeCtrl.clear();
        await _loadVouchers();
      } else {
        final msg = data is Map ? data['message']?.toString() : null;
        messenger.showSnackBar(
          SnackBar(
            content: Text(msg ?? 'Mã "$code" không hợp lệ hoặc đã hết hạn'),
            backgroundColor: Colors.orange[700],
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Mã "$code" không hợp lệ hoặc đã hết hạn'),
          backgroundColor: Colors.orange[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mã khuyến mãi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: const Color(0xFF888888),
          indicatorColor: _kPrimary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Có thể dùng'),
            Tab(text: 'Đã dùng / Hết hạn'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã khuyến mãi',
                      hintStyle: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _applying ? null : _applyCode,
                  child: _applying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  )
                : _error != null
                ? _errorView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(
                        _available,
                        emptyMsg: 'Chưa có mã khuyến mãi nào',
                      ),
                      _buildList(
                        _expired,
                        emptyMsg: 'Chưa có mã đã dùng / hết hạn',
                        icon: Icons.history,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Lỗi tải dữ liệu',
            style: const TextStyle(color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadVouchers,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items, {
    required String emptyMsg,
    IconData icon = Icons.local_offer_outlined,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(emptyMsg, style: const TextStyle(color: Color(0xFF888888))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadVouchers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _voucherCard(items[i]),
      ),
    );
  }

  Widget _voucherCard(Map<String, dynamic> v) {
    final type = (v['type'] ?? 'percentage').toString();
    final value = (v['value'] as num?)?.toDouble() ?? 0;
    final discount = type == 'percentage'
        ? '${value.toStringAsFixed(0)}%'
        : '${_formatVnd(value)}đ';
    final endRaw = v['end_date'];
    String expiry = '-';
    if (endRaw is String) {
      final d = DateTime.tryParse(endRaw);
      if (d != null) expiry = '${d.day}/${d.month}/${d.year}';
    }
    final code = (v['code'] ?? '').toString();
    final title = (v['name'] ?? code).toString();
    final desc =
        v['description']?.toString() ??
        (v['min_order_amount'] != null
            ? 'Áp dụng cho đơn từ ${_formatVnd((v['min_order_amount'] as num).toDouble())}đ'
            : 'Áp dụng cho mọi đơn hàng');
    const color = _kPrimary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  discount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'HSD: $expiry',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(double v) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }
}
