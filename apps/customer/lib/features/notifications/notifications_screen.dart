import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';
import 'notification_badge_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get<dynamic>('/notifications');
      final wrapper = res.data?['data'];
      final data = wrapper is Map
          ? wrapper['data']
          : (wrapper is List ? wrapper : []);
      if (mounted) {
        setState(() {
          _notifications = data is List
              ? data.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _markRead(String id) async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.patch<dynamic>('/notifications/$id/read');
      if (!mounted) return;
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx >= 0 && _notifications[idx]['is_read'] != true) {
          _notifications[idx]['is_read'] = true;
          context.read<NotificationBadgeCubit>().decrement();
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đánh dấu được, thử lại sau')),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.patch<dynamic>('/notifications/read-all');
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
      context.read<NotificationBadgeCubit>().clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đánh dấu được, thử lại sau')),
      );
    }
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

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
          'Thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: _kPrimary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => _skeletonItem(),
      );
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 48,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải thông báo',
              style: TextStyle(color: Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadNotifications,
              child: const Text('Thử lại', style: TextStyle(color: _kPrimary)),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Chưa có thông báo nào',
              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Các cập nhật về đơn hàng sẽ hiện ở đây',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _notifCard(_notifications[i]),
      ),
    );
  }

  Widget _notifCard(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] as String? ?? 'general';

    return GestureDetector(
      onTap: () => _markRead(notif['id'] as String),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(12),
          border: isRead
              ? null
              : Border.all(color: const Color(0xFFFFD0BA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif['title'] as String? ?? 'Thông báo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notif['created_at']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonItem() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'loyalty':
        return Icons.star_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF1565C0);
      case 'promotion':
        return _kPrimary;
      case 'delivery':
        return const Color(0xFF2E7D32);
      case 'loyalty':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final d = DateTime.parse(ts.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}
