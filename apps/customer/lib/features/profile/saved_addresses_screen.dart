import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/auth_cubit.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<CustomerAuthCubit>().api;
      final res = await api.get<dynamic>('/customers/me/addresses');
      // API wraps response: {statusCode, data: [...], timestamp}
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List)
          ? raw['data'] as List
          : (raw is List ? raw : []);
      if (mounted) {
        setState(() {
          _addresses = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _addAddress(Map<String, dynamic> input) async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.post<dynamic>('/customers/me/addresses', data: input);
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  Future<void> _deleteAddress(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa địa chỉ'),
        content: const Text('Bạn có chắc muốn xóa địa chỉ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.delete<dynamic>('/customers/me/addresses/$id');
      await _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      final api = context.read<CustomerAuthCubit>().api;
      await api.patch<dynamic>('/customers/me/addresses/$id/default');
      await _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red[700]),
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
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Địa chỉ đã lưu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm địa chỉ mới',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showAddressDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 12),
            const Text('Không thể tải địa chỉ', style: TextStyle(color: Color(0xFF888888))),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadAddresses, child: const Text('Thử lại', style: TextStyle(color: _kPrimary))),
          ],
        ),
      );
    }
    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Chưa có địa chỉ nào', style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Thêm địa chỉ để thanh toán nhanh hơn',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadAddresses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: _addresses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _addressCard(_addresses[i]),
      ),
    );
  }

  Widget _addressCard(Map<String, dynamic> addr) {
    final isDefault = addr['is_default'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: _kPrimary, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDefault ? const Color(0xFFFFE5D9) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: isDefault ? _kPrimary : const Color(0xFF999999), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(addr['label'] ?? 'Địa chỉ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5D9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Mặc định',
                            style: TextStyle(color: _kPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${addr['full_name'] ?? ''} • ${addr['phone'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 4),
                Text(_buildAddressText(addr),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFAAAAAA), size: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') _deleteAddress(addr['id'] as String);
              if (value == 'default') _setDefault(addr['id'] as String);
              if (value == 'edit') _showAddressDialog(context, existing: addr);
            },
            itemBuilder: (_) => [
              if (!isDefault)
                const PopupMenuItem(value: 'default', child: Text('Đặt làm mặc định')),
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              const PopupMenuItem(
                  value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  String _buildAddressText(Map<String, dynamic> addr) {
    final parts = <String>[
      if (addr['address'] != null && (addr['address'] as String).isNotEmpty) addr['address'] as String,
      if (addr['ward'] != null && (addr['ward'] as String).isNotEmpty) addr['ward'] as String,
      if (addr['district'] != null && (addr['district'] as String).isNotEmpty) addr['district'] as String,
      if (addr['city'] != null && (addr['city'] as String).isNotEmpty) addr['city'] as String,
    ];
    return parts.join(', ');
  }

  void _showAddressDialog(BuildContext context, {Map<String, dynamic>? existing}) {
    final labelCtrl = TextEditingController(text: existing?['label'] as String? ?? 'Nhà');
    final nameCtrl = TextEditingController(text: existing?['full_name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] as String? ?? '');
    final addressCtrl = TextEditingController(text: existing?['address'] as String? ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] as String? ?? '');
    final districtCtrl = TextEditingController(text: existing?['district'] as String? ?? '');
    final wardCtrl = TextEditingController(text: existing?['ward'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(context).viewInsets.bottom + 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Thêm địa chỉ mới' : 'Chỉnh sửa địa chỉ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(labelCtrl, 'Tên địa chỉ', 'Nhà, Công ty...'),
              const SizedBox(height: 12),
              _field(nameCtrl, 'Họ tên người nhận', 'Nhập họ tên'),
              const SizedBox(height: 12),
              _field(phoneCtrl, 'Số điện thoại', '0901234567',
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(addressCtrl, 'Địa chỉ (số nhà, tên đường)', 'VD: 123 Lê Lợi',
                  maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(wardCtrl, 'Phường/Xã', 'Phường...')),
                const SizedBox(width: 10),
                Expanded(child: _field(districtCtrl, 'Quận/Huyện', 'Quận...')),
              ]),
              const SizedBox(height: 12),
              _field(cityCtrl, 'Tỉnh/Thành phố', 'TP. Hồ Chí Minh'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty ||
                        addressCtrl.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền đủ họ tên, SĐT và địa chỉ'),
                            backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    final data = {
                      'label': labelCtrl.text.trim().isEmpty ? 'Nhà' : labelCtrl.text.trim(),
                      'full_name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'city': cityCtrl.text.trim(),
                      'district': districtCtrl.text.trim(),
                      'ward': wardCtrl.text.trim(),
                    };
                    if (existing != null) {
                      final api = context.read<CustomerAuthCubit>().api;
                      try {
                        await api.put<dynamic>('/customers/me/addresses/${existing['id']}', data: data);
                        await _loadAddresses();
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red[700]),
                          );
                      }
                    } else {
                      await _addAddress(data);
                    }
                  },
                  child: Text(existing == null ? 'Lưu địa chỉ' : 'Cập nhật',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF444444))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ],
    );
  }
}
