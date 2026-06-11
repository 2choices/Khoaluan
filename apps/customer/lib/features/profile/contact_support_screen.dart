import 'package:flutter/material.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'Đơn hàng';
  bool _sending = false;

  final List<String> _categories = [
    'Đơn hàng',
    'Thanh toán',
    'Giao hàng',
    'Sản phẩm',
    'Tài khoản',
    'Khác',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
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
          'Liên hệ hỗ trợ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick contact
            Row(
              children: [
                Expanded(
                  child: _quickContactBtn(
                    Icons.phone_outlined,
                    'Gọi điện',
                    '1800 6868',
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gọi hotline: 1800 6868')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickContactBtn(
                    Icons.chat_outlined,
                    'Live Chat',
                    '24/7',
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng chat đang được phát triển')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Gửi yêu cầu hỗ trợ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF999999), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại vấn đề', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFFE5D9) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: selected ? Border.all(color: _kPrimary) : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected ? _kPrimary : const Color(0xFF666666),
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tiêu đề', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectCtrl,
                    decoration: InputDecoration(
                      hintText: 'Mô tả ngắn về vấn đề...',
                      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nội dung chi tiết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _sending ? null : _sendRequest,
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickContactBtn(IconData icon, String label, String detail, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFFFE5D9), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(detail, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _sending = false);
      _subjectCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu hỗ trợ. Chúng tôi sẽ phản hồi trong 24 giờ.'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
