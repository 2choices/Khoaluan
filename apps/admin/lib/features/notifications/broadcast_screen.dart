import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all';
  String _type = 'system';
  bool _sending = false;
  String? _resultMsg;
  Color _resultColor = OmnigoColors.success;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() {
        _resultMsg = 'Vui lòng nhập tiêu đề và nội dung';
        _resultColor = OmnigoColors.error;
      });
      return;
    }
    setState(() {
      _sending = true;
      _resultMsg = null;
    });
    try {
      final api = context.read<AuthCubit>().api;
      final res = await api.post<dynamic>('/notifications/broadcast', data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _type,
        'audience': _audience,
      });
      final raw = res.data;
      final data = (raw is Map && raw['data'] is Map) ? raw['data'] as Map : raw;
      final count = data is Map ? data['count'] : null;
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resultMsg = 'Đã gửi thông báo tới ${count ?? '?'} người dùng';
        _resultColor = OmnigoColors.success;
        _titleCtrl.clear();
        _bodyCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _resultMsg = 'Lỗi: $e';
        _resultColor = OmnigoColors.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gửi thông báo broadcast',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: OmnigoColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Gửi tin nhắn tới toàn bộ khách hàng hoặc nhân viên trong cửa hàng.',
                  style: TextStyle(color: OmnigoColors.textSecondary)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đối tượng nhận',
                        style: TextStyle(fontWeight: FontWeight.w600, color: OmnigoColors.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _audienceChip('all', 'Tất cả'),
                        _audienceChip('customers', 'Khách hàng'),
                        _audienceChip('staff', 'Nhân viên'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Loại thông báo',
                        style: TextStyle(fontWeight: FontWeight.w600, color: OmnigoColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('Hệ thống')),
                        DropdownMenuItem(value: 'promotion', child: Text('Khuyến mãi')),
                        DropdownMenuItem(value: 'order', child: Text('Đơn hàng')),
                        DropdownMenuItem(value: 'announcement', child: Text('Thông báo chung')),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'system'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Tiêu đề',
                        style: TextStyle(fontWeight: FontWeight.w600, color: OmnigoColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Khuyến mãi cuối tuần',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nội dung',
                        style: TextStyle(fontWeight: FontWeight.w600, color: OmnigoColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Nội dung thông báo...',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_resultMsg != null)
                          Expanded(
                            child: Text(_resultMsg!,
                                style: TextStyle(color: _resultColor, fontWeight: FontWeight.w500)),
                          )
                        else
                          const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OmnigoColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: Text(_sending ? 'Đang gửi...' : 'Gửi thông báo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _audienceChip(String value, String label) {
    final selected = _audience == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _audience = value),
      selectedColor: OmnigoColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : OmnigoColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}
