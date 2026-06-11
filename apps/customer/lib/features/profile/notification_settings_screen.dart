import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);
const _kPrefix = 'notif_';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newProducts = false;
  bool _priceAlerts = true;
  bool _deliveryUpdates = true;
  bool _appNotif = true;
  bool _emailNotif = false;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool('${_kPrefix}order_updates') ?? true;
      _promotions = prefs.getBool('${_kPrefix}promotions') ?? true;
      _newProducts = prefs.getBool('${_kPrefix}new_products') ?? false;
      _priceAlerts = prefs.getBool('${_kPrefix}price_alerts') ?? true;
      _deliveryUpdates = prefs.getBool('${_kPrefix}delivery_updates') ?? true;
      _appNotif = prefs.getBool('${_kPrefix}app') ?? true;
      _emailNotif = prefs.getBool('${_kPrefix}email') ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_kPrefix}order_updates', _orderUpdates);
      await prefs.setBool('${_kPrefix}promotions', _promotions);
      await prefs.setBool('${_kPrefix}new_products', _newProducts);
      await prefs.setBool('${_kPrefix}price_alerts', _priceAlerts);
      await prefs.setBool('${_kPrefix}delivery_updates', _deliveryUpdates);
      await prefs.setBool('${_kPrefix}app', _appNotif);
      await prefs.setBool('${_kPrefix}email', _emailNotif);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt thông báo'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không lưu được, thử lại sau'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          'Cài đặt thông báo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Đơn hàng'),
                  _settingsCard([
                    _switchTile(
                      Icons.receipt_long_outlined,
                      'Cập nhật đơn hàng',
                      'Thông báo khi trạng thái đơn hàng thay đổi',
                      _orderUpdates,
                      (v) => setState(() => _orderUpdates = v),
                    ),
                    const Divider(height: 1, indent: 56),
                    _switchTile(
                      Icons.local_shipping_outlined,
                      'Cập nhật giao hàng',
                      'Thông báo khi đơn hàng đang được vận chuyển',
                      _deliveryUpdates,
                      (v) => setState(() => _deliveryUpdates = v),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionTitle('Ưu đãi & Khuyến mãi'),
                  _settingsCard([
                    _switchTile(
                      Icons.local_offer_outlined,
                      'Khuyến mãi & Ưu đãi',
                      'Nhận thông báo về các chương trình giảm giá',
                      _promotions,
                      (v) => setState(() => _promotions = v),
                    ),
                    const Divider(height: 1, indent: 56),
                    _switchTile(
                      Icons.new_releases_outlined,
                      'Sản phẩm mới',
                      'Thông báo khi có sản phẩm mới ra mắt',
                      _newProducts,
                      (v) => setState(() => _newProducts = v),
                    ),
                    const Divider(height: 1, indent: 56),
                    _switchTile(
                      Icons.trending_down_outlined,
                      'Cảnh báo giá',
                      'Thông báo khi sản phẩm yêu thích giảm giá',
                      _priceAlerts,
                      (v) => setState(() => _priceAlerts = v),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionTitle('Kênh thông báo'),
                  _settingsCard([
                    _switchTile(
                      Icons.notifications_outlined,
                      'Thông báo đẩy',
                      'Nhận thông báo trên điện thoại',
                      _appNotif,
                      (v) => setState(() => _appNotif = v),
                    ),
                    const Divider(height: 1, indent: 56),
                    _switchTile(
                      Icons.email_outlined,
                      'Email',
                      'Nhận thông báo qua email',
                      _emailNotif,
                      (v) => setState(() => _emailNotif = v),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Lưu cài đặt',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5D9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kPrimary,
            activeTrackColor: const Color(0xFFFFE5D9),
          ),
        ],
      ),
    );
  }
}
