import 'package:flutter/material.dart';

const _kBg = Color(0xFFFFF5F0);

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
          'Điều khoản sử dụng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cập nhật lần cuối: 09/04/2026', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
            const SizedBox(height: 20),
            _section('1. Giới thiệu',
                'OMNIGO ("chúng tôi", "ứng dụng") là nền tảng thương mại điện tử kết nối người mua và người bán. Bằng việc sử dụng ứng dụng, bạn đồng ý với các điều khoản sử dụng dưới đây.'),
            _section('2. Tài khoản người dùng',
                '• Bạn phải cung cấp thông tin chính xác khi đăng ký.\n• Bạn chịu trách nhiệm bảo mật tài khoản và mật khẩu.\n• OMNIGO có quyền đình chỉ tài khoản vi phạm điều khoản.'),
            _section('3. Đặt hàng và thanh toán',
                '• Đơn hàng được xác nhận sau khi thanh toán thành công.\n• Giá sản phẩm hiển thị đã bao gồm VAT.\n• Chúng tôi hỗ trợ thanh toán qua VietQR và thanh toán khi nhận hàng (COD).'),
            _section('4. Chính sách hoàn trả',
                '• Sản phẩm có thể được hoàn trả trong vòng 7 ngày kể từ ngày nhận.\n• Sản phẩm phải còn nguyên tem, chưa qua sử dụng.\n• Chi phí vận chuyển hoàn hàng do người mua chịu (trừ trường hợp lỗi từ phía chúng tôi).'),
            _section('5. Quyền riêng tư',
                'Chúng tôi thu thập thông tin cần thiết để vận hành dịch vụ và không chia sẻ thông tin cá nhân của bạn với bên thứ ba không có thẩm quyền. Xem thêm Chính sách Bảo mật để biết chi tiết.'),
            _section('6. Giới hạn trách nhiệm',
                'OMNIGO không chịu trách nhiệm về thiệt hại gián tiếp, đặc biệt, ngẫu nhiên hoặc hậu quả phát sinh từ việc sử dụng hoặc không thể sử dụng dịch vụ.'),
            _section('7. Thay đổi điều khoản',
                'Chúng tôi có quyền cập nhật điều khoản sử dụng bất kỳ lúc nào. Thông báo sẽ được gửi qua email hoặc thông báo trong ứng dụng khi có thay đổi quan trọng.'),
            _section('8. Liên hệ',
                'Nếu bạn có thắc mắc về điều khoản sử dụng, vui lòng liên hệ:\n• Email: legal@omnigo.vn\n• Hotline: 1800 6868\n• Địa chỉ: TP. Hồ Chí Minh, Việt Nam'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bằng cách tiếp tục sử dụng OMNIGO, bạn xác nhận đã đọc, hiểu và đồng ý với các điều khoản trên.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), fontStyle: FontStyle.italic, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.6)),
        ],
      ),
    );
  }
}
