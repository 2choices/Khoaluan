import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthCubit>().signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        }
        if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: OmnigoColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          color: OmnigoColors.background,
          child: Center(
            child: SingleChildScrollView(
              padding: OmnigoBreakpoints.pagePadding(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: EdgeInsets.all(
                  OmnigoBreakpoints.isCompact(context) ? 24 : 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OmnigoLogo(
                      size: 80,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OMNIGO Admin',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: OmnigoColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập vào bảng điều khiển',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    OmnigoTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'admin@omnigo.vn',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    OmnigoTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Nhập mật khẩu',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return OmnigoButton(
                          label: 'Đăng nhập',
                          onPressed: _handleLogin,
                          loading: state.status == AuthStatus.loading,
                          expanded: true,
                          size: OmnigoButtonSize.large,
                        );
                      },
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
