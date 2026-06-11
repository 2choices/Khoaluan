import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<CustomerAuthCubit>().state.user;
    _nameCtrl.text = user?.userMetadata?['full_name'] as String? ?? '';
    _phoneCtrl.text = user?.userMetadata?['phone'] as String? ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập họ tên'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final cubit = context.read<CustomerAuthCubit>();
      await cubit.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật hồ sơ'), backgroundColor: Color(0xFF2E7D32)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
                    builder: (context, state) {
                      final name = state.user?.userMetadata?['full_name'] as String? ?? '?';
                      final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                      return CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFFFE5D9),
                        child: Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _kPrimary)),
                      );
                    },
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin cá nhân', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _field(_nameCtrl, 'Họ và tên *', Icons.person_outlined),
                  const SizedBox(height: 12),
                  _field(_phoneCtrl, 'Số điện thoại', Icons.phone_outlined, type: TextInputType.phone),
                  const SizedBox(height: 12),
                  // Email (readonly)
                  BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
                    builder: (context, state) {
                      return TextField(
                        readOnly: true,
                        controller: TextEditingController(text: state.user?.email ?? ''),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, color: _kPrimary, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: const Icon(Icons.lock_outline, color: Color(0xFFCCCCCC), size: 18),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OmnigoButton(
              label: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
              expanded: true,
              size: OmnigoButtonSize.large,
              loading: _saving,
              onPressed: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
