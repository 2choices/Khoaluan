import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpCtrl = TextEditingController();
  int _resendCooldown = 0;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP phải gồm 6 chữ số'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await context.read<CustomerAuthCubit>().verifyEmailOtp(widget.email, otp);
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    try {
      final email =
          context.read<CustomerAuthCubit>().state.pendingEmail ?? widget.email;
      await context.read<CustomerAuthCubit>().resendSignUpOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lại mã OTP vào email của bạn'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      setState(() => _resendCooldown = 30);
      while (mounted && _resendCooldown > 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() => _resendCooldown--);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không gửi lại được OTP. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.trim().isEmpty) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Xác minh email'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: _kPrimary, size: 36),
                const SizedBox(height: 10),
                const Text(
                  'Không tìm thấy email cần xác minh. Vui lòng đăng ký lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF555555)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.go('/login'),
                  child: const Text('Về màn đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocListener<CustomerAuthCubit, CustomerAuthState>(
      listener: (context, state) {
        if (state.status == CustomerAuthStatus.authenticated) {
          context.go('/home');
        } else if (state.status == CustomerAuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Xác minh email'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.mark_email_unread_outlined,
                        color: _kPrimary, size: 46),
                    const SizedBox(height: 12),
                    const Text(
                      'Nhập mã OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã gồm 6 chữ số đã gửi tới ${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        letterSpacing: 6,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '------',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
                      builder: (_, state) {
                        final loading = state.status == CustomerAuthStatus.loading;
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: loading ? null : _verify,
                          child: Text(loading ? 'Đang xác minh...' : 'Xác minh'),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resendCooldown > 0 ? null : _resend,
                      child: Text(
                        _resendCooldown > 0
                            ? 'Gửi lại OTP sau $_resendCooldown giây'
                            : 'Gửi lại OTP',
                        style: const TextStyle(color: _kPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Quay lại đăng nhập',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
