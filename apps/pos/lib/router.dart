import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_cubit.dart';
import 'features/auth/login_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/shift/shift_screen.dart';
import 'features/orders/order_history_screen.dart';

GoRouter createPosRouter(
  PosAuthCubit authCubit, {
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: '/pos',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = authCubit.state;
      final status = authState.status;

      final isLoggedIn = status == PosAuthStatus.authenticated;
      final isLoggedOut = status == PosAuthStatus.unauthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // Khi auth còn đang check/loading thì không redirect vội.
      if (!isLoggedIn && !isLoggedOut) {
        return null;
      }

      if (isLoggedOut && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return '/pos';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const PosLoginScreen(),
      ),
      GoRoute(
        path: '/pos',
        builder: (_, _) => const PosScreen(),
      ),
      GoRoute(
        path: '/shift',
        builder: (_, _) => const ShiftScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, _) => const OrderHistoryScreen(),
      ),
    ],
  );
}