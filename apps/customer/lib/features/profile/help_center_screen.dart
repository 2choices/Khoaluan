import 'package:flutter/material.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          'Trung tâm trợ giúp',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text('Chúng tôi luôn sẵn sàng hỗ trợ bạn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Tìm câu trả lời cho các thắc mắc của bạn', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Câu hỏi thường gặp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _faqCard(context, 'Làm thế nào để đặt hàng?', 'Tìm sản phẩm bạn muốn → Thêm vào giỏ → Thanh toán. Đơn hàng sẽ được xử lý trong vòng 24 giờ.'),
            _faqCard(context, 'Chính sách hoàn trả như thế nào?', 'Bạn có thể hoàn trả sản phẩm trong vòng 7 ngày kể từ ngày nhận hàng nếu sản phẩm có lỗi.'),
            _faqCard(context, 'Thời gian giao hàng bao lâu?', 'Nội thành TP.HCM: 1-2 ngày. Các tỉnh thành khác: 3-5 ngày làm việc.'),
            _faqCard(context, 'Làm sao để hủy đơn hàng?', 'Vào "Đơn hàng của tôi" → Chọn đơn hàng cần hủy → Nhấn "Hủy đơn hàng". Chỉ áp dụng trước khi giao hàng.'),
            _faqCard(context, 'Điểm thưởng được tính như thế nào?', 'Mỗi 1.000đ mua hàng = 1 điểm. Tích lũy 1.000 điểm = giảm 10.000đ cho đơn hàng tiếp theo.'),
            const SizedBox(height: 20),
            const Text('Liên hệ hỗ trợ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _contactCard(
              Icons.chat_outlined,
              'Chat trực tuyến',
              'Hỗ trợ 24/7 qua chat',
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng chat đang được phát triển')),
              ),
            ),
            _contactCard(
              Icons.phone_outlined,
              'Hotline: 1800 6868',
              'Thứ 2-6: 8:00 - 20:00',
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gọi hotline: 1800 6868')),
              ),
            ),
            _contactCard(
              Icons.email_outlined,
              'Email: support@omnigo.vn',
              'Phản hồi trong vòng 24 giờ',
              () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email: support@omnigo.vn')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqCard(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
        iconColor: _kPrimary,
        collapsedIconColor: const Color(0xFFAAAAAA),
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Text(answer, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
        ],
      ),
    );
  }

  Widget _contactCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: const Color(0xFFFFE5D9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _kPrimary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
        onTap: onTap,
      ),
    );
  }
}
