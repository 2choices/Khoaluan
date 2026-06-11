import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_cubit.dart';
import '../../shared/layout/customer_responsive.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
      builder: (context, state) {
        final name =
            state.user?.userMetadata?['full_name'] as String? ?? 'Khách hàng';
        final email = state.user?.email ?? '';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return SingleChildScrollView(
          child: Column(
            children: [
              // AppBar area
              Container(
                color: _kBg,
                padding: CustomerResponsive.headerPadding(context, bottom: 0),
                child: Row(
                  children: [
                    const Text(
                      'Tài khoản',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: _kPrimary,
                      ),
                      onPressed: () => context.push('/notification-settings'),
                    ),
                  ],
                ),
              ),

              // Profile card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFFFE5D9),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => context.push('/edit-profile'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Chỉnh sửa hồ sơ >',
                              style: TextStyle(
                                color: _kPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Loyalty points card — solid primary
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Hạng Vàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Xem ưu đãi >',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '0 điểm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.1,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thu thập điểm để lên hạng Kim Cương 💎',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Order section
              _sectionTitle('Đơn hàng'),
              _menuSection([
                _menuItem(
                  Icons.receipt_long_outlined,
                  'Lịch sử đơn hàng',
                  null,
                  () => context.go('/orders'),
                ),
                _menuItem(
                  Icons.favorite_border,
                  'Sản phẩm yêu thích',
                  null,
                  () => context.push('/favorites'),
                ),
                _menuItem(
                  Icons.star_outline,
                  'Đánh giá của tôi',
                  null,
                  () => context.push('/my-reviews'),
                ),
              ]),

              const SizedBox(height: 8),
              _sectionTitle('Thanh toán'),
              _menuSection([
                _menuItem(
                  Icons.credit_card_outlined,
                  'Phương thức thanh toán',
                  null,
                  () => context.push('/payment-methods'),
                ),
                _menuItem(
                  Icons.local_offer_outlined,
                  'Mã khuyến mãi',
                  null,
                  () => context.push('/vouchers'),
                ),
              ]),

              const SizedBox(height: 8),
              _sectionTitle('Cài đặt'),
              _menuSection([
                _menuItem(
                  Icons.location_on_outlined,
                  'Địa chỉ đã lưu',
                  null,
                  () => context.push('/saved-addresses'),
                ),
                _menuItem(
                  Icons.notifications_outlined,
                  'Cài đặt thông báo',
                  null,
                  () => context.push('/notification-settings'),
                ),
                _menuItem(
                  Icons.language_outlined,
                  'Ngôn ngữ',
                  'Tiếng Việt',
                  () => _showLanguageSheet(context),
                ),
              ]),

              const SizedBox(height: 8),
              _sectionTitle('Hỗ trợ'),
              _menuSection([
                _menuItem(
                  Icons.help_outline,
                  'Trung tâm trợ giúp',
                  null,
                  () => context.push('/help-center'),
                ),
                _menuItem(
                  Icons.phone_outlined,
                  'Liên hệ hỗ trợ',
                  null,
                  () => context.push('/contact-support'),
                ),
                _menuItem(
                  Icons.description_outlined,
                  'Điều khoản sử dụng',
                  null,
                  () => context.push('/terms'),
                ),
              ]),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: _kPrimary,
                      size: 22,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () => context.read<CustomerAuthCubit>().signOut(),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'OMNIGO v1.0.0',
                style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF999999),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _menuSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    String? badge,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: _kPrimary, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5D9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: _kPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ngôn ngữ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.check_circle, color: _kPrimary),
                title: const Text('Tiếng Việt'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
