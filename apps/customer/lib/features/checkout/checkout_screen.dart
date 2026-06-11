import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:api_client/api_client.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../auth/auth_cubit.dart';
import '../cart/cart_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _paymentMethod = 'cash';
  bool _placing = false;

  final _voucherCtrl = TextEditingController();
  bool _applyingVoucher = false;
  String? _voucherCode;
  String? _voucherId;
  double _voucherDiscount = 0;
  String? _voucherError;

  bool _loadingAddrs = true;
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  bool _saveNewAddress = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<CustomerAuthCubit>().state.user;
    _nameCtrl.text = user?.userMetadata?['full_name'] as String? ?? '';
    _phoneCtrl.text = user?.userMetadata?['phone'] as String? ?? '';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<CustomerAuthCubit>();

    final profile = await auth.fetchMyProfile();
    if (profile != null && mounted) {
      if (_nameCtrl.text.isEmpty) {
        _nameCtrl.text = (profile['full_name'] as String?) ?? _nameCtrl.text;
      }
      if (_phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = (profile['phone'] as String?) ?? _phoneCtrl.text;
      }
    }

    try {
      final res = await auth.api.get<dynamic>('/customers/me/addresses');
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List)
          ? raw['data'] as List
          : (raw is List ? raw : []);

      _savedAddresses =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (_savedAddresses.isNotEmpty) {
        final def = _savedAddresses.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => _savedAddresses.first,
        );
        _applyAddress(def);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loadingAddrs = false);
    }
  }

  void _applyAddress(Map<String, dynamic> a) {
    _selectedAddressId = a['id'] as String?;
    final recipient = (a['full_name'] as String?) ??
        (a['recipient_name'] as String?) ??
        (a['name'] as String?);
    final phone = a['phone'] as String?;

    if (recipient != null && recipient.isNotEmpty) {
      _nameCtrl.text = recipient;
    }
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = phone;
    }
    _addressCtrl.text = _formatAddress(a);
  }

  String _formatAddress(Map<String, dynamic> a) {
    final parts = <String>[
      if ((a['address'] as String?)?.isNotEmpty == true) a['address'] as String,
      if ((a['address_line'] as String?)?.isNotEmpty == true)
        a['address_line'] as String,
      if ((a['ward'] as String?)?.isNotEmpty == true) a['ward'] as String,
      if ((a['district'] as String?)?.isNotEmpty == true)
        a['district'] as String,
      if ((a['city'] as String?)?.isNotEmpty == true) a['city'] as String,
    ];

    if (parts.isEmpty && a['full_address'] is String) {
      return a['full_address'] as String;
    }
    return parts.join(', ');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _voucherCode = null;
        _voucherId = null;
        _voucherDiscount = 0;
        _voucherError = null;
      });
      return;
    }

    setState(() {
      _applyingVoucher = true;
      _voucherError = null;
    });

    try {
      final cartState = context.read<CartCubit>().state;
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.post<dynamic>(
        '/vouchers/validate',
        data: {
          'code': code,
          'orderAmount': cartState.totalAmount,
        },
      );

      final data = _asMap(_unwrapData(res.data));
      final voucher = data['voucher'];
      final discount = (data['discount'] as num?)?.toDouble() ?? 0;

      setState(() {
        _voucherCode = code;
        _voucherId = voucher is Map ? voucher['id']?.toString() : null;
        _voucherDiscount = discount;
        _applyingVoucher = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Áp dụng mã “$code” — giảm ${_fmt(discount)}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      final msg = e.toString();
      String display = 'Mã không hợp lệ';
      final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
      if (m != null) display = m.group(1) ?? display;

      setState(() {
        _voucherCode = null;
        _voucherId = null;
        _voucherDiscount = 0;
        _voucherError = display;
        _applyingVoucher = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ tên người nhận'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.length < 9 ||
        phone.length > 11 ||
        !RegExp(r'^[0-9+]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số điện thoại không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ giao hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _placing = true);

    try {
      final cartState = context.read<CartCubit>().state;
      final api = context.read<CustomerAuthCubit>().api;

      final items = cartState.items
          .map((e) => {
                'product_id': e.productId,
                'quantity': e.quantity,
                'unit_price': e.price,
              })
          .toList();

      final orderRes = await api.post<dynamic>(
        '/orders',
        data: {
          'items': items,
          'payment_method':
              _paymentMethod == 'bank_transfer' ? 'bank_transfer' : 'cash',
          'shipping_address': _addressCtrl.text.trim(),
          'shipping_phone': _phoneCtrl.text.trim(),
          'shipping_name': _nameCtrl.text.trim(),
          'note': _noteCtrl.text.trim(),
          'source': 'online',
          if (_voucherId != null) 'voucher_id': _voucherId,
          if (_voucherDiscount > 0) 'discount_amount': _voucherDiscount,
        },
      );

      final orderMap = _asMap(_unwrapData(orderRes.data));
      final orderId = orderMap['id']?.toString();

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Không lấy được mã đơn hàng sau khi tạo đơn');
      }

      if (_paymentMethod == 'bank_transfer') {
        final payosRes = await api.post<dynamic>(
          '/payments/payos',
          data: {'orderId': orderId},
        );

        final payData = _asMap(_unwrapData(payosRes.data));
        final checkoutUrl = payData['checkoutUrl']?.toString();
        final qrCode = payData['qrCode']?.toString();

        final hasCheckout = checkoutUrl != null && checkoutUrl.isNotEmpty;
        final hasQr = qrCode != null && qrCode.isNotEmpty;

        if (!hasCheckout && !hasQr) {
          throw Exception('Không tạo được mã QR thanh toán. Vui lòng thử lại.');
        }

        if (mounted) {
          setState(() => _placing = false);
          await _showPayOSDialog(
            orderId: orderId,
            checkoutUrl: checkoutUrl,
            qrCode: qrCode,
          );
        }
        return;
      }

      if (_saveNewAddress && _selectedAddressId == null) {
        try {
          await api.post<dynamic>(
            '/customers/me/addresses',
            data: {
              'full_name': _nameCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'address': _addressCtrl.text.trim(),
              'is_default': _savedAddresses.isEmpty,
            },
          );
        } catch (_) {}
      }

      if (mounted) {
        context.read<CartCubit>().clearCart();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt hàng thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final lvl1 = raw['data'];
      if (lvl1 is Map && lvl1['data'] != null) {
        return lvl1['data'];
      }
      return lvl1;
    }
    return raw;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Future<void> _showPayOSDialog({
    required String orderId,
    String? checkoutUrl,
    String? qrCode,
  }) {
    final api = context.read<CustomerAuthCubit>().api;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PayOSDialog(
        orderId: orderId,
        checkoutUrl: checkoutUrl,
        qrCode: qrCode,
        api: api,
        onPaid: () {
          Navigator.of(dialogCtx).pop();
          context.read<CartCubit>().clearCart();
          _showSuccessDialog();
        },
        onCancelled: () {
          Navigator.of(dialogCtx).pop();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã hủy đơn. Vui lòng chọn Thanh toán tiền mặt và đặt lại.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _paymentMethod = 'cash');
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đặt hàng thành công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đơn hàng của bạn đã được ghi nhận.\nChúng tôi sẽ liên hệ sớm nhất có thể.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              OmnigoButton(
                label: 'Xem đơn hàng',
                expanded: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/orders');
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                child: const Text(
                  'Tiếp tục mua sắm',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
        ),
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              title: 'Sản phẩm đã chọn',
              child: Column(
                children: [
                  ...cartState.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFFF5F5F5),
                              child: item.thumbnail != null
                                  ? Image.network(
                                      item.thumbnail!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.image,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Color(0xFFCCCCCC),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_fmt(item.price)} × ${item.quantity}',
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _fmt(item.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tạm tính',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _fmt(cartState.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (_voucherDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giảm giá ($_voucherCode)',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '-${_fmt(_voucherDiscount)}',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _fmt(
                          (cartState.totalAmount - _voucherDiscount)
                              .clamp(0, double.infinity),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Mã giảm giá',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _voucherCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Nhập mã (ví dụ: WELCOME10)',
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _applyingVoucher ? null : _applyVoucher,
                        child: Text(_applyingVoucher ? '...' : 'Áp dụng'),
                      ),
                    ],
                  ),
                  if (_voucherError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _voucherError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  if (_voucherCode != null && _voucherDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Đã áp dụng “$_voucherCode” — giảm ${_fmt(_voucherDiscount)}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Thông tin giao hàng',
              child: Column(
                children: [
                  if (_loadingAddrs)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFFF0F0F0),
                        valueColor: AlwaysStoppedAnimation(_kPrimary),
                        minHeight: 2,
                      ),
                    )
                  else if (_savedAddresses.isNotEmpty) ...[
                    _addressPicker(),
                    const SizedBox(height: 12),
                  ],
                  _inputField(
                    _nameCtrl,
                    'Họ tên người nhận',
                    Icons.person_outlined,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    _phoneCtrl,
                    'Số điện thoại',
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    _addressCtrl,
                    'Địa chỉ giao hàng *',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedAddressId == null)
                    Row(
                      children: [
                        Checkbox(
                          value: _saveNewAddress,
                          activeColor: _kPrimary,
                          onChanged: (v) =>
                              setState(() => _saveNewAddress = v ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Lưu địa chỉ này để dùng cho lần sau',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  _inputField(
                    _noteCtrl,
                    'Ghi chú đơn hàng (tùy chọn)',
                    Icons.note_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _sectionCard(
              title: 'Phương thức thanh toán',
              child: Column(
                children: [
                  _paymentOption(
                    'cash',
                    Icons.money,
                    'Thanh toán tiền mặt',
                    'Trả tiền khi nhận hàng',
                  ),
                  const SizedBox(height: 8),
                  _paymentOption(
                    'bank_transfer',
                    Icons.account_balance_outlined,
                    'Chuyển khoản ngân hàng',
                    'Thanh toán qua QR Code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: OmnigoButton(
          label: _placing
              ? 'Đang đặt hàng...'
              : 'Xác nhận đặt hàng · ${_fmt((cartState.totalAmount - _voucherDiscount).clamp(0, double.infinity))}',
          expanded: true,
          size: OmnigoButtonSize.large,
          loading: _placing,
          onPressed: _placing ? () {} : _placeOrder,
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _paymentOption(
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0EB) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? _kPrimary : const Color(0xFF888888),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? _kPrimary
                          : const Color(0xFF1A1A1A),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _kPrimary : const Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedAddressId,
          hint: const Text(
            'Chọn địa chỉ đã lưu',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: _kPrimary),
          items: [
            ..._savedAddresses.map((a) {
              final id = a['id'] as String;
              final label = _formatAddress(a);
              final isDef = a['is_default'] == true;
              return DropdownMenuItem(
                value: id,
                child: Row(
                  children: [
                    Icon(
                      isDef ? Icons.star : Icons.location_on_outlined,
                      size: 16,
                      color: isDef ? _kPrimary : const Color(0xFF888888),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const DropdownMenuItem(
              value: '__new__',
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: _kPrimary),
                  SizedBox(width: 8),
                  Text(
                    'Nhập địa chỉ mới',
                    style: TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v == '__new__') {
              setState(() {
                _selectedAddressId = null;
                _addressCtrl.clear();
              });
              return;
            }
            final addr = _savedAddresses.firstWhere((a) => a['id'] == v);
            setState(() => _applyAddress(addr));
          },
        ),
      ),
    );
  }

  String _fmt(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}đ';
  }
}

class _PayOSDialog extends StatefulWidget {
  final String orderId;
  final String? checkoutUrl;
  final String? qrCode;
  final NestJSClient api;
  final VoidCallback onPaid;
  final VoidCallback onCancelled;

  const _PayOSDialog({
    required this.orderId,
    required this.checkoutUrl,
    required this.qrCode,
    required this.api,
    required this.onPaid,
    required this.onCancelled,
  });

  @override
  State<_PayOSDialog> createState() => _PayOSDialogState();
}

class _PayOSDialogState extends State<_PayOSDialog> {
  bool _checking = false;
  bool _cancelling = false;

  Future<void> _checkPayment() async {
    setState(() => _checking = true);
    try {
      final confirmRes = await widget.api.post<dynamic>(
        '/payments/payos/confirm-order',
        data: {'orderId': widget.orderId},
      );

      final raw = confirmRes.data;
      Map<String, dynamic> data = {};

      if (raw is Map && raw['data'] != null) {
        final lvl1 = raw['data'];
        if (lvl1 is Map && lvl1['data'] is Map) {
          data = Map<String, dynamic>.from(lvl1['data'] as Map);
        } else if (lvl1 is Map) {
          data = Map<String, dynamic>.from(lvl1);
        }
      } else if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      }

      final success = data['success'] == true;
      if (!mounted) return;

      if (success) {
        widget.onPaid();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể xác nhận thanh toán. Vui lòng thử lại.'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _checking = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác nhận thanh toán lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _checking = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có thể đặt lại và chọn Thanh toán tiền mặt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _cancelling = true);

    try {
      await widget.api.put<dynamic>(
        '/orders/${widget.orderId}/cancel',
        data: {},
      );
      if (!mounted) return;
      widget.onCancelled();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hủy đơn thất bại: $e'),
          backgroundColor: Colors.red,
        ),
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
                  const Text(
                    'Thanh toán chuyển khoản',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vui lòng quét QR hoặc mở link để thanh toán. Sau khi thanh toán, bấm “Tôi đã thanh toán” để xác nhận.',
                    style: TextStyle(color: Color(0xFF666666), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (qr != null && qr.isNotEmpty) ...[
                    const Text(
                      'Mã QR ngân hàng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (qr.startsWith('http'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          qr,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => SelectableText(qr),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qr,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              qr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (url != null && url.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Link thanh toán',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                  OmnigoButton(
                    label: _checking ? 'Đang xác nhận...' : 'Tôi đã thanh toán',
                    expanded: true,
                    loading: _checking,
                    onPressed: busy ? () {} : _checkPayment,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy ? null : _cancelOrder,
                      child: Text(
                        _cancelling
                            ? 'Đang hủy...'
                            : 'Hủy đơn & chọn tiền mặt',
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