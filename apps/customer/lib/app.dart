import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:api_client/api_client.dart';
import 'features/ai/ai_cubit.dart';
import 'features/auth/auth_cubit.dart';
import 'features/cart/cart_cubit.dart';
import 'features/notifications/notification_badge_cubit.dart';
import 'router.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CustomerAuthCubit(
            SupabaseClientProvider.client,
            NestJSClient(
              baseUrl: const String.fromEnvironment(
                'API_URL',
                defaultValue: 'http://localhost:3000/api/v1',
              ),
            ),
          )..checkAuth(),
        ),
        BlocProvider(
          create: (ctx) => AiCubit(ctx.read<CustomerAuthCubit>().api),
        ),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(
          create: (ctx) =>
              NotificationBadgeCubit(ctx.read<CustomerAuthCubit>().api),
        ),
      ],
      child: const _CustomerAppView(),
    );
  }
}

class _CustomerAppView extends StatefulWidget {
  const _CustomerAppView();

  @override
  State<_CustomerAppView> createState() => _CustomerAppViewState();
}

class _CustomerAppViewState extends State<_CustomerAppView> {
  late final _RouterRefreshStream _routerRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<CustomerAuthCubit>();
    _routerRefresh = _RouterRefreshStream(
      authCubit.stream
          .map((s) => s.status)
          .where(
            (s) =>
                s == CustomerAuthStatus.authenticated ||
                s == CustomerAuthStatus.unauthenticated,
          )
          .distinct(),
    );
    _router = createCustomerRouter(
      authCubit,
      refreshListenable: _routerRefresh,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _routerRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'OMNIGO Shop',
      debugShowCheckedModeBanner: false,
      theme: OmnigoTheme.light.copyWith(
        scaffoldBackgroundColor: _kBg,
        colorScheme: OmnigoTheme.light.colorScheme.copyWith(
          primary: _kPrimary,
          onPrimary: Colors.white,
        ),
        appBarTheme: OmnigoTheme.light.appBarTheme.copyWith(
          backgroundColor: _kBg,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _kPrimary.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: _kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(color: Color(0xFF888888), fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: _kPrimary);
            }
            return const IconThemeData(color: Color(0xFF888888));
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),
      darkTheme: OmnigoTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

class _RouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _RouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
