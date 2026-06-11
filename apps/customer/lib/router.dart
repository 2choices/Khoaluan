import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/verify_otp_screen.dart';
import 'features/home/home_screen.dart';
import 'features/products/product_list_screen.dart';
import 'features/products/product_detail_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/orders/my_orders_screen.dart';
import 'features/orders/order_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/saved_addresses_screen.dart';
import 'features/profile/notification_settings_screen.dart';
import 'features/profile/payment_methods_screen.dart';
import 'features/profile/vouchers_screen.dart';
import 'features/profile/favorites_screen.dart';
import 'features/profile/my_reviews_screen.dart';
import 'features/profile/help_center_screen.dart';
import 'features/profile/contact_support_screen.dart';
import 'features/profile/terms_screen.dart';
import 'features/search/search_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'shared/layout/customer_shell.dart';
import 'shared/layout/customer_responsive.dart';

GoRouter createCustomerRouter(
  CustomerAuthCubit authCubit, {
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggedIn = authState.status == CustomerAuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isVerifyOtpRoute = state.matchedLocation == '/verify-otp';

      if (!isLoggedIn && !isLoginRoute && !isVerifyOtpRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const CustomerLoginScreen()),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) => VerifyOtpScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (_, state, child) =>
            CustomerShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (_, _) => const ProductListScreen(),
          ),
          GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const MyOrdersScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ],
      ),
      // Routes ngoài shell (full-screen)
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => CustomerResponsiveRoute(
          child: ProductDetailScreen(
            productId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: CheckoutScreen()),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => CustomerResponsiveRoute(
          child: OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: EditProfileScreen()),
      ),
      GoRoute(
        path: '/saved-addresses',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: SavedAddressesScreen()),
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: NotificationSettingsScreen()),
      ),
      GoRoute(
        path: '/payment-methods',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: PaymentMethodsScreen()),
      ),
      GoRoute(
        path: '/vouchers',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: VouchersScreen()),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: FavoritesScreen()),
      ),
      GoRoute(
        path: '/my-reviews',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: MyReviewsScreen()),
      ),
      GoRoute(
        path: '/help-center',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: HelpCenterScreen()),
      ),
      GoRoute(
        path: '/contact-support',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: ContactSupportScreen()),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, _) => const CustomerResponsiveRoute(child: TermsScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) => const CustomerResponsiveRoute(child: SearchScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) =>
            const CustomerResponsiveRoute(child: NotificationsScreen()),
      ),
    ],
  );
}
