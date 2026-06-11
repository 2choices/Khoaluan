import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client_provider.dart';

/// Dio interceptor that automatically attaches the current Supabase JWT
/// to every outgoing request targeting the NestJS backend.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? token = SupabaseClientProvider.currentAccessToken;

    // Trên web, session restore là async — chờ tối đa 3s
    if (token == null || token.isEmpty) {
      token = await _waitForToken(maxWaitMs: 3000);
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      developer.log(
        'AuthInterceptor: No access token available for ${options.uri}',
        name: 'api_client',
        level: 900,
      );
    }

    handler.next(options);
  }

  /// Chờ cho đến khi Supabase restore session xong (web-safe).
  Future<String?> _waitForToken({int maxWaitMs = 3000}) async {
    const interval = 100;
    int waited = 0;
    while (waited < maxWaitMs) {
      final token = SupabaseClientProvider.currentAccessToken;
      if (token != null && token.isNotEmpty) return token;

      // Kiểm tra session qua stream event nếu có
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) return session.accessToken;

      await Future.delayed(const Duration(milliseconds: interval));
      waited += interval;
    }
    return SupabaseClientProvider.currentAccessToken;
  }
}
