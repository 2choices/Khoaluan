import 'package:flutter/material.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [
    {
      'id': '1',
      'type': 'vietqr',
      'label': 'VietQR / Chuyển khoản',
      'detail': 'Thanh toán qua mã QR ngân hàng',
      'icon': Icons.qr_code,
      'isDefault': true,
    },
    {
      'id': '2',
      'type': 'cod',
      'label': 'Thanh toán khi nhận hàng',
      'detail': 'Trả tiền mặt khi giao hàng',
      'icon': Icons.payments_outlined,
      'isDefault': false,
    },
  ];

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
          'Phương thức thanh toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phương thức đã lưu',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Column(
                children: _methods.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return Column(
                    children: [
                      if (i > 0) const Divider(height: 1, indent: 16),
                      ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: m['isDefault'] == true ? const Color(0xFFFFE5D9) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(m['icon'] as IconData, color: m['isDefault'] == true ? _kPrimary : const Color(0xFF888888), size: 22),
                        ),
                        title: Text(m['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text(m['detail'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        trailing: m['isDefault'] == true
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE5D9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Mặc định', style: TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                              )
                            : TextButton(
                                onPressed: () {
                                  setState(() {
                                    for (final method in _methods) {
                                      method['isDefault'] = method['id'] == m['id'];
                                    }
                                  });
                                },
                                child: const Text('Đặt mặc định', style: TextStyle(color: _kPrimary, fontSize: 12)),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OMNIGO hỗ trợ thanh toán qua VietQR và COD. Thẻ tín dụng sẽ được hỗ trợ trong phiên bản tiếp theo.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
