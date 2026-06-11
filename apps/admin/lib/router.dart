import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/products/products_screen.dart';
import 'features/orders/orders_screen.dart' as orders;
import 'features/orders/order_detail_screen.dart' as order_detail;
import 'features/customers/customers_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/employees/employees_screen.dart';
import 'features/vouchers/vouchers_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/ai/ai_analytics_screen.dart';
import 'features/notifications/broadcast_screen.dart';
import 'shared/layout/admin_scaffold.dart';

GoRouter createRouter(
  AuthCubit authCubit, {
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (_, state, child) => AdminScaffold(
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (_, _) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, _) => const orders.OrdersScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) => order_detail.OrderDetailScreen(
              orderId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/customers',
            builder: (_, _) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, _) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/employees',
            builder: (_, _) => const EmployeesScreen(),
          ),
          GoRoute(
            path: '/vouchers',
            builder: (_, _) => const VouchersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/broadcast',
            builder: (_, _) => const BroadcastScreen(),
          ),
          GoRoute(
            path: '/ai-analytics',
            builder: (_, _) => const AiAnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
}