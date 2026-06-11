import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:api_client/api_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../pos_cubit.dart';

class PaymentDialog extends StatefulWidget {
  final double total;
  const PaymentDialog({super.key, required this.total});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  late TextEditingController _amountController;
  String _method = 'cash';
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.total.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(300.0, 420.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: OmnigoColors.primary),
                const SizedBox(width: 8),
                const Text('Thanh toán',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OmnigoColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Tổng thanh toán',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(widget.total),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: OmnigoColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('Số tiền khách đưa',
                style: TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiền thừa:',
                    style: TextStyle(color: Colors.grey)),
                Text(
                  _formatPrice(_calculateChange()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: OmnigoColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Phương thức thanh toán',
                style: TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 8),

            _methodOption('cash', '💵 Tiền mặt'),
            _methodOption('bank_transfer', '🏦 Chuyển khoản'),
            _methodOption('vietqr', '🏧 VietQR'),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _processing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OmnigoColors.success,
                  foregroundColor: Colors.white,
                ),
                child: _processing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodOption(String value, String label) {
    final isSelected = _method == value;

    return ListTile(
      title: Text(label),
      leading: Radio(
        value: value,
        groupValue: _method,
        onChanged: (v) => setState(() => _method = v!),
      ),
      tileColor:
          isSelected ? OmnigoColors.primary.withValues(alpha: 0.08) : null,
    );
  }

  double _calculateChange() {
    try {
      final amount = double.parse(_amountController.text);
      return (amount - widget.total).clamp(0, double.infinity);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _handlePayment() async {
    try {
      final amount = double.parse(_amountController.text);

      if (amount < widget.total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Số tiền không đủ')),
        );
        return;
      }

      setState(() => _processing = true);

      final cubit = context.read<PosCubit>();
      final order =
          await cubit.checkout(method: _method, paidAmount: amount);

      // VietQR (PayOS): order đã được tạo + duyệt nhưng CHƯA thanh toán.
      // Tạo mã QR PayOS và hiển thị để khách quét, chỉ xác nhận thành công
      // sau khi PayOS báo đã nhận tiền.
      if (_method == 'vietqr') {
        await _handleVietQrPayment(cubit, order);
        return;
      }

      cubit.clearCart();

      if (!mounted) return;

      Navigator.pop(context);
      _showResult(order);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
      setState(() => _processing = false);
    }
  }

  Future<void> _handleVietQrPayment(
    PosCubit cubit,
    Map<String, dynamic> order,
  ) async {
    final orderId = order['id']?.toString() ?? '';
    if (orderId.isEmpty) {
      throw Exception('Không tạo được đơn hàng');
    }

    // Tạo thanh toán PayOS để lấy mã QR ngân hàng + link thanh toán.
    final payRes = await cubit.api.post<dynamic>(
      '/payments/payos',
      data: {'orderId': orderId},
    );
    final payData = _unwrapMap(payRes.data);
    final qrCode = payData['qrCode']?.toString();
    final checkoutUrl = payData['checkoutUrl']?.toString();
    if ((qrCode == null || qrCode.isEmpty) &&
        (checkoutUrl == null || checkoutUrl.isEmpty)) {
      throw Exception('Không tạo được mã QR thanh toán');
    }

    if (!mounted) return;

    // Dùng context của Navigator (ổn định) để hiển thị các dialog tiếp theo
    // sau khi đóng dialog thanh toán hiện tại.
    final navigator = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context); // đóng dialog thanh toán

    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (dCtx) => _PosPayOSDialog(
        orderId: orderId,
        qrCode: qrCode,
        checkoutUrl: checkoutUrl,
        api: cubit.api,
        onPaid: () {
          Navigator.pop(dCtx);
          cubit.clearCart();
          _showResultIn(navigator.context, order);
        },
        onCancelled: () => Navigator.pop(dCtx),
      ),
    );
  }

  /// Bóc tách response API có thể lồng dưới một hoặc hai khoá `data`.
  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final lvl1 = raw['data'];
      if (lvl1 is Map && lvl1['data'] is Map) {
        return Map<String, dynamic>.from(lvl1['data'] as Map);
      }
      if (lvl1 is Map) return Map<String, dynamic>.from(lvl1);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  void _showResult(Map<String, dynamic> order) {
    _showResultIn(context, order);
  }

  void _showResultIn(BuildContext ctx, Map<String, dynamic> order) {
    showDialog(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Thanh toán thành công'),
        content: Text('Mã đơn: ${order['order_number'] ?? '-'}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  String _formatPrice(double value) {
    return '${value.toStringAsFixed(0)} đ';
  }
}
/// Dialog hiển thị mã QR PayOS/VietQR cho POS. Khách quét QR để chuyển khoản,
/// sau đó thu ngân bấm "Tôi đã thanh toán" để xác minh với backend.
class _PosPayOSDialog extends StatefulWidget {
  final String orderId;
  final String? qrCode;
  final String? checkoutUrl;
  final NestJSClient api;
  final VoidCallback onPaid;
  final VoidCallback onCancelled;

  const _PosPayOSDialog({
    required this.orderId,
    required this.qrCode,
    required this.checkoutUrl,
    required this.api,
    required this.onPaid,
    required this.onCancelled,
  });

  @override
  State<_PosPayOSDialog> createState() => _PosPayOSDialogState();
}

class _PosPayOSDialogState extends State<_PosPayOSDialog> {
  bool _checking = false;
  bool _cancelling = false;

  Future<void> _checkPayment() async {
    setState(() => _checking = true);
    try {
      // Chủ động yêu cầu backend xác minh với PayOS trước, để việc xác nhận
      // không phụ thuộc hoàn toàn vào webhook bất đồng bộ.
      bool isPaid = false;
      try {
        final verifyRes = await widget.api.post<dynamic>(
          '/payments/payos/verify',
          data: {'orderId': widget.orderId},
        );
        final verify = _extractMap(verifyRes.data);
        isPaid = verify['paid'] == true || verify['payment_status'] == 'paid';
      } catch (_) {
        // Bỏ qua và đọc trạng thái đơn hàng bên dưới.
      }

      if (!isPaid) {
        final res = await widget.api.get<dynamic>('/orders/${widget.orderId}');
        final order = _extractMap(res.data);
        final paymentStatus = order['payment_status']?.toString();
        final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0;
        isPaid = paymentStatus == 'paid' ||
            (paymentStatus == 'partial' && paidAmount > 0);
      }
      if (!mounted) return;
      if (isPaid) {
        widget.onPaid();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Chưa nhận được thanh toán. Vui lòng thử lại sau khi quét QR.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _checking = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Kiểm tra thanh toán lỗi: $e'),
            backgroundColor: Colors.red),
      );
      setState(() => _checking = false);
    }
  }

  /// Bóc tách response API có thể lồng dưới một hoặc hai khoá `data`.
  Map _extractMap(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final lvl1 = raw['data'];
      if (lvl1 is Map && lvl1['data'] is Map) return lvl1['data'] as Map;
      if (lvl1 is Map) return lvl1;
    }
    if (raw is Map) return raw;
    return {};
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có thể tạo lại và chọn Thanh toán tiền mặt.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Hủy đơn',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      await widget.api
          .put<dynamic>('/orders/${widget.orderId}/cancel', data: {});
      if (!mounted) return;
      widget.onCancelled();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hủy đơn thất bại: $e'), backgroundColor: Colors.red),
      );
      setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = widget.qrCode;
    final url = widget.checkoutUrl;
    final busy = _checking || _cancelling;
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thanh toán chuyển khoản',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Mời khách quét QR hoặc mở link để thanh toán. Sau khi khách thanh toán, bấm “Tôi đã thanh toán” để kiểm tra.',
                    style: TextStyle(color: Color(0xFF666666), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (qr != null && qr.isNotEmpty) ...[
                    const Text('Mã QR ngân hàng',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (qr.startsWith('http'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          qr,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _RawQrFallback(data: qr),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: QrImageView(
                            data: qr,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            errorStateBuilder: (context, error) =>
                                _RawQrFallback(data: qr),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (url != null && url.isNotEmpty) ...[
                    const Text('Link thanh toán',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(url),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: busy ? null : _checkPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OmnigoColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: _checking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Tôi đã thanh toán'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Color(0xFFE57373)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: busy ? null : _cancelOrder,
                      child: Text(
                        _cancelling ? 'Đang hủy...' : 'Hủy đơn',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback hiển thị chuỗi QR dạng text khi không render được ảnh QR.
class _RawQrFallback extends StatelessWidget {
  final String data;
  const _RawQrFallback({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(data),
    );
  }
}
