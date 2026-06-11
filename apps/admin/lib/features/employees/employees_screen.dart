import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import '../auth/auth_cubit.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final api = context.read<AuthCubit>().api;
      final response = await api.get('/employees');
      if (mounted) {
        setState(() {
          final data = response.data?['data'];
          final employeeList = data is Map ? data['data'] : data;
          _employees = employeeList is List
              ? employeeList
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()
              : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: OmnigoBreakpoints.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                'Nhân viên',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );
              final action = OmnigoButton(
                label: 'Thêm nhân viên',
                prefixIcon: Icons.person_add,
                onPressed: _showEmployeeDialog,
              );

              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 12), action],
                );
              }

              return Row(children: [title, const Spacer(), action]);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: OmnigoLoading())
                : _employees.isEmpty
                ? const Center(child: Text('Chưa có nhân viên nào'))
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = (constraints.maxWidth / 320)
            .floor()
            .clamp(1, 3)
            .toInt();
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 420 ? 2.2 : 2.6,
          ),
          itemCount: _employees.length,
          itemBuilder: (_, i) => _employeeCard(_employees[i]),
        );
      },
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final user = emp['user'] is Map
        ? Map<String, dynamic>.from(emp['user'] as Map)
        : <String, dynamic>{};
    final fullName = '${user['full_name'] ?? emp['full_name'] ?? 'Nhân viên'}';
    final contact =
        '${user['phone'] ?? emp['phone'] ?? user['email'] ?? emp['email'] ?? ''}';
    final role = '${emp['position'] ?? emp['role'] ?? 'Nhân viên'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: OmnigoColors.primary.withValues(alpha: 0.1),
            child: Text(
              fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: OmnigoColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  contact,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: emp['is_active'] == true
                  ? OmnigoColors.success.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              emp['is_active'] == true ? 'Hoạt động' : 'Khóa',
              style: TextStyle(
                fontSize: 11,
                color: emp['is_active'] == true
                    ? OmnigoColors.success
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmployeeDialog() async {
    final userIdCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final departmentCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm nhân viên'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(dialogContext).width - 80).clamp(
            280.0,
            420.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OmnigoTextField(
                  controller: userIdCtrl,
                  label: 'User ID',
                  hint: 'UUID tài khoản đã có',
                ),
                const SizedBox(height: 12),
                OmnigoTextField(controller: codeCtrl, label: 'Mã nhân viên'),
                const SizedBox(height: 12),
                OmnigoTextField(controller: positionCtrl, label: 'Chức vụ'),
                const SizedBox(height: 12),
                OmnigoTextField(controller: departmentCtrl, label: 'Bộ phận'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdCtrl.text.trim();
              if (userId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập User ID')),
                );
                return;
              }

              try {
                final api = context.read<AuthCubit>().api;
                await api.post(
                  '/employees',
                  data: {
                    'user_id': userId,
                    'employee_code': codeCtrl.text.trim().isEmpty
                        ? null
                        : codeCtrl.text.trim(),
                    'position': positionCtrl.text.trim().isEmpty
                        ? null
                        : positionCtrl.text.trim(),
                    'department': departmentCtrl.text.trim().isEmpty
                        ? null
                        : departmentCtrl.text.trim(),
                    'is_active': true,
                  },
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadEmployees();
              } catch (_) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể thêm nhân viên'),
                    backgroundColor: OmnigoColors.error,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    userIdCtrl.dispose();
    codeCtrl.dispose();
    positionCtrl.dispose();
    departmentCtrl.dispose();
  }
}
