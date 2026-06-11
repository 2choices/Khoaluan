import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  // Tách hàm ép kiểu an toàn tránh lỗi kiểu dữ liệu num/string từ server
  double _safeCastToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<void> _loadOrder() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final api = context.read<AuthCubit>().api;
      final response = await api.get('/orders/${widget.orderId}');
      
      if (mounted) {
        final data = response.data?['data'];
        setState(() {
          _order = data is Map ? Map<String, dynamic>.from(data) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại cấu hình API IP Network.";
          _loading = false;
        });
      }
    }
  }

  Future<void> _approveOrder() async {
    try {
      final api = context.read<AuthCubit>().api;
      // Dùng trực tiếp widget.orderId để đảm bảo độ chính xác của tài nguyên endpoint
      await api.post('/orders/${widget.orderId}/approve');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận đơn hàng thành công!'),
            backgroundColor: OmnigoColors.success,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác nhận: Kết nối máy chủ thất bại hoặc sai endpoint.'),
            backgroundColor: OmnigoColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeOrder() async {
    try {
      final api = context.read<AuthCubit>().api;
      await api.put('/orders/${widget.orderId}/status', data: {'status': 'completed'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hoàn thành đơn thành công'),
            backgroundColor: OmnigoColors.success,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: OmnigoColors.error),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn chắc chắn muốn hủy đơn này?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Không')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final api = context.read<AuthCubit>().api;
      await api.put('/orders/${widget.orderId}/cancel');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn thành công'), backgroundColor: OmnigoColors.primary),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi hủy: $e'), backgroundColor: OmnigoColors.error),
        );
      }
    }
  }

  Future<void> _recordPayment() async {
    if (_order == null) return;
    final method = _order!['payment_method']?.toString() ?? 'cash';
    final totalAmount = _safeCastToDouble(_order!['total_amount']);
    final paidAmount = _safeCastToDouble(_order!['paid_amount']);
    final remaining = totalAmount - paidAmount;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn đã thanh toán đầy đủ')),
      );
      return;
    }

    final controller = TextEditingController(text: remaining.toStringAsFixed(0));

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                label: const Text('Số tiền'),
                hintText: remaining.toStringAsFixed(0),
              ),
            ),
            const SizedBox(height: 12),
            Text('Phương thức: ${_formatPaymentMethod(method)}'),
            const SizedBox(height: 8),
            Text('Còn lại: ${_formatCurrency(remaining)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final text = controller.text;
              ctx.pop();
              try {
                final amount = double.parse(text);
                final api = context.read<AuthCubit>().api;
                await api.post(
                  '/orders/${widget.orderId}/payment',
                  data: {
                    'amount': amount,
                    'method': method,
                  },
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ghi nhận thanh toán thành công'), backgroundColor: OmnigoColors.success),
                  );
                  _loadOrder();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi thanh toán: $e'), backgroundColor: OmnigoColors.error),
                  );
                }
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: OmnigoLoading())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⚠️ $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadOrder, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Không tìm thấy dữ liệu đơn hàng này.'))
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: OmnigoBreakpoints.pagePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(),
                              const SizedBox(height: 20),
                              _buildCustomerSection(),
                              const SizedBox(height: 20),
                              _buildItemsSection(),
                              const SizedBox(height: 20),
                              _buildTotalSection(),
                              const SizedBox(height: 20),
                              _buildPaymentSection(),
                              const SizedBox(height: 20),
                              _buildActionsSection(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeaderSection() {
    final status = _order!['status']?.toString() ?? 'draft';
    final orderNumber = _order!['order_number']?.toString() ?? '-';
    final createdAt = _order!['created_at']?.toString() ?? '';

    return OmnigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#$orderNumber',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: OmnigoColors.primary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ngày: ${_formatDate(createdAt)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Nguồn: ${_formatOrderSource(_order!['source']?.toString() ?? '')}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    final customerName = _order!['customer_name']?.toString() ?? 'Khách lẻ';
    final customerPhone = _order!['customer_phone']?.toString() ?? '-';

    return OmnigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin khách hàng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20, color: OmnigoColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(customerPhone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = _order!['items'] as List? ?? [];

    return OmnigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm (${items.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('Không có sản phẩm')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (_, i) {
                final item = items[i] as Map<String, dynamic>;
                final name = item['product_name']?.toString() ?? '';
                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                final unitPrice = _safeCastToDouble(item['unit_price']);
                final total = _safeCastToDouble(item['total']);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '$quantity × ${_formatCurrency(unitPrice)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: OmnigoColors.primary),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final subtotal = _safeCastToDouble(_order!['subtotal']);
    final discount = _safeCastToDouble(_order!['discount_amount']);
    final shipping = _safeCastToDouble(_order!['shipping_fee']);
    final total = _safeCastToDouble(_order!['total_amount']);

    return OmnigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalRow('Tạm tính', subtotal, Colors.grey[600]),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('Giảm giá', -discount, Colors.red),
          ],
          if (shipping > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('Vận chuyển', shipping, Colors.grey[600]),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 12),
          _buildTotalRow(
            'Tổng cộng',
            total,
            OmnigoColors.primary,
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final method = _order!['payment_method']?.toString() ?? 'cash';
    final paymentStatus = _order!['payment_status']?.toString() ?? 'pending';
    final totalAmount = _safeCastToDouble(_order!['total_amount']);
    final paidAmount = _safeCastToDouble(_order!['paid_amount']);
    final changeAmount = _safeCastToDouble(_order!['change_amount']);
    final remaining = totalAmount - paidAmount;

    return OmnigoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thanh toán',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentStatus == 'paid' ? OmnigoColors.success : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatPaymentStatus(paymentStatus),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Phương thức: ${_formatPaymentMethod(method)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildTotalRow('Đã thanh toán', paidAmount, Colors.grey[600]),
          if (remaining > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('Còn lại', remaining, Colors.red),
          ],
          if (changeAmount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow('Tiền thừa', changeAmount, OmnigoColors.success),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    final status = _order!['status']?.toString() ?? 'draft';
    final paymentStatus = _order!['payment_status']?.toString() ?? 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'draft') ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OmnigoColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _approveOrder,
            child: const Text('Xác nhận đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
        if (status == 'confirmed' || status == 'processing') ...[
          if (paymentStatus != 'paid') ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _recordPayment,
              child: const Text(
                'Ghi nhận thanh toán',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OmnigoColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _completeOrder,
            child: const Text('Hoàn thành', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
        if (status != 'completed' && status != 'cancelled') ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _cancelOrder,
            child: const Text('Hủy đơn'),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalRow(String label, double value, Color? color, {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: large ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        label = 'Đã xác nhận';
        icon = Icons.check_circle;
        break;
      case 'processing':
        color = Colors.orange;
        label = 'Đang xử lý';
        icon = Icons.hourglass_top;
        break;
      case 'completed':
        color = OmnigoColors.success;
        label = 'Hoàn thành';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        color = OmnigoColors.error;
        label = 'Đã hủy';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        label = 'Chờ xử lý';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  String _formatDate(String? date) {
    if (date == null) return '-';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '-';
    }
  }

  String _formatPaymentMethod(String method) {
    final map = {
      'cash': '💵 Tiền mặt',
      'bank_transfer': '🏦 Chuyển khoản',
      'payos': '🏧 PayOS',
      'momo': '📱 MoMo',
      'vnpay': '💳 VNPay',
      'card': '💳 Thẻ',
    };
    return map[method] ?? method;
  }

  String _formatPaymentStatus(String status) {
    return switch (status) {
      'paid' => 'Đã thanh toán',
      'partial' => 'Thanh toán một phần',
      'pending' => 'Chưa thanh toán',
      'refunded' => 'Hoàn tiền',
      _ => status,
    };
  }

  String _formatOrderSource(String source) {
    return switch (source) {
      'pos' => '🏪 POS',
      'online' => '🌐 Online',
      'kiosk' => '🖥️ Kiosk',
      _ => source,
    };
  }
}