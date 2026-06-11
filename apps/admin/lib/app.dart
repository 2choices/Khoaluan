import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:api_client/api_client.dart';
import 'features/auth/auth_cubit.dart';
import 'router.dart';

const _kPrimary = Color(0xFFC84B1A);
const _kBg = Color(0xFFFFF5F0);

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        SupabaseClientProvider.client,
        NestJSClient(
          baseUrl: const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://localhost:3000/api/v1',
          ),
        ),
      )..checkAuth(),
      child: const _AdminAppView(),
    );
  }
}

class _AdminAppView extends StatefulWidget {
  const _AdminAppView();

  @override
  State<_AdminAppView> createState() => _AdminAppViewState();
}

class _AdminAppViewState extends State<_AdminAppView> {
  late final _RouterRefreshStream _routerRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    _routerRefresh = _RouterRefreshStream(
      authCubit.stream
          .map((s) => s.status)
          .where(
            (s) =>
                s == AuthStatus.authenticated ||
                s == AuthStatus.unauthenticated,
          )
          .distinct(),
    );
    _router = createRouter(
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
      title: 'OMNIGO Admin',
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
