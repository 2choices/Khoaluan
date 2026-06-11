import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'auth_cubit.dart';

class PosLoginScreen extends StatefulWidget {
  const PosLoginScreen({super.key});

  @override
  State<PosLoginScreen> createState() => _PosLoginScreenState();
}

class _PosLoginScreenState extends State<PosLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

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
    context.read<PosAuthCubit>().signIn(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosAuthCubit, PosAuthState>(
      listener: (context, state) {
        if (state.status == PosAuthStatus.authenticated) {
          context.go('/pos');
        }
        if (state.status == PosAuthStatus.error && state.errorMessage != null) {
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
                constraints: const BoxConstraints(maxWidth: 400),
                padding: EdgeInsets.all(
                  OmnigoBreakpoints.isCompact(context) ? 24 : 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OmnigoLogo(
                      size: 72,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OMNIGO POS',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: OmnigoColors.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đăng nhập để bắt đầu bán hàng',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    OmnigoTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'staff@omnigo.vn',
                      prefixIcon: Icons.person_outlined,
                    ),
                    const SizedBox(height: 14),
                    OmnigoTextField(
                      controller: _passwordController,
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
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<PosAuthCubit, PosAuthState>(
                      builder: (context, state) {
                        return OmnigoButton(
                          label: 'Đăng nhập',
                          onPressed: _handleLogin,
                          loading: state.status == PosAuthStatus.loading,
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
