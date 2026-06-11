import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      _showError('Vui lòng nhập email');
      return;
    }
    if (!RegExp(r'^[\w\-.]+@[\w\-]+\.\w+$').hasMatch(email)) {
      _showError('Email không hợp lệ');
      return;
    }
    if (password.isEmpty) {
      _showError('Vui lòng nhập mật khẩu');
      return;
    }
    if (_isRegister) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showError('Vui lòng nhập họ tên');
        return;
      }
      if (password.length < 6) {
        _showError('Mật khẩu phải ít nhất 6 ký tự');
        return;
      }
      context.read<CustomerAuthCubit>().signUp(
        email,
        password,
        _nameCtrl.text.trim(),
      );
    } else {
      context.read<CustomerAuthCubit>().signIn(email, password);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Nhập email để đặt lại mật khẩu');
      return;
    }
    try {
      await context.read<CustomerAuthCubit>().resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi email đặt lại mật khẩu, kiểm tra hộp thư'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showError('Không thể gửi email. Kiểm tra lại địa chỉ email.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerAuthCubit, CustomerAuthState>(
      listener: (context, state) {
        if (state.status == CustomerAuthStatus.authenticated) {
          context.go('/home');
        } else if (state.status == CustomerAuthStatus.otpRequired) {
          final email = state.pendingEmail ?? _emailCtrl.text.trim();
          if (email.isNotEmpty) {
            final encoded = Uri.encodeQueryComponent(email);
            context.go('/verify-otp?email=$encoded');
          }
        }
        if (state.status == CustomerAuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const OmnigoLogo(
                    size: 80,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OMNIGO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRegister
                        ? 'Tạo tài khoản mới'
                        : 'Chào mừng bạn trở lại!',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isRegister) ...[
                          OmnigoTextField(
                            controller: _nameCtrl,
                            label: 'Họ tên',
                            hint: 'Nhập họ tên',
                            prefixIcon: Icons.person_outlined,
                          ),
                          const SizedBox(height: 14),
                        ],
                        OmnigoTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'email@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        OmnigoTextField(
                          controller: _passwordCtrl,
                          label: 'Mật khẩu',
                          hint: 'Nhập mật khẩu',
                          prefixIcon: Icons.lock_outlined,
                          obscureText: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                        const SizedBox(height: 24),
                        if (!_isRegister)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: _kPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        if (!_isRegister) const SizedBox(height: 8),
                        BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
                          builder: (context, state) {
                            final isLoading =
                                state.status == CustomerAuthStatus.loading;
                            return OmnigoButton(
                              label: _isRegister ? 'Đăng ký' : 'Đăng nhập',
                              onPressed: _handleSubmit,
                              loading: isLoading,
                              expanded: true,
                              size: OmnigoButtonSize.large,
                            );
                          },
                        ),
                        if (_isRegister)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              'Sau khi đăng ký, hệ thống sẽ gửi OTP qua email để xác minh tài khoản.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF777777),
                                height: 1.35,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegister = !_isRegister;
                      _emailCtrl.clear();
                      _passwordCtrl.clear();
                      _nameCtrl.clear();
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        children: [
                          TextSpan(
                            text: _isRegister
                                ? 'Đã có tài khoản? '
                                : 'Chưa có tài khoản? ',
                          ),
                          TextSpan(
                            text: _isRegister ? 'Đăng nhập' : 'Đăng ký',
                            style: const TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
