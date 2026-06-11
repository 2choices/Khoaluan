import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Thông tin cửa hàng',
            Icons.store,
            [
              _settingTile('Tên cửa hàng', 'OMNIGO Store', Icons.edit_outlined),
              _settingTile('Địa chỉ', 'TP. Hồ Chí Minh', Icons.edit_outlined),
              _settingTile('Số điện thoại', '0901234567', Icons.edit_outlined),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Thanh toán',
            Icons.payment,
            [
              _settingTile('PayOS', 'Đã kết nối', Icons.check_circle, color: OmnigoColors.success),
              _settingTile('Tiền mặt', 'Bật', Icons.toggle_on, color: OmnigoColors.success),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'In & hóa đơn',
            Icons.print,
            [
              _settingTile('Máy in mặc định', 'Chưa thiết lập', Icons.settings),
              _settingTile('Mẫu hóa đơn', 'Mặc định', Icons.receipt),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Tài khoản',
            Icons.person,
            [
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  return _settingTile(
                    'Email',
                    state.user?.email ?? '',
                    Icons.email,
                  );
                },
              ),
              _settingTile('Đổi mật khẩu', '', Icons.lock),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: OmnigoButton(
              label: 'Đăng xuất',
              variant: OmnigoButtonVariant.outline,
              prefixIcon: Icons.logout,
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: OmnigoColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _settingTile(String title, String subtitle, IconData trailing, {Color? color}) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: Icon(trailing, size: 18, color: color ?? Colors.grey),
    );
  }
}
