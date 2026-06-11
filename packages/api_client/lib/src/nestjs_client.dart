import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Dio-based HTTP client for the OMNIGO NestJS backend API.
///
/// Features:
/// - Automatic Supabase JWT attachment via [AuthInterceptor].
/// - Automatic error mapping via [ErrorInterceptor].
/// - Convenience methods for common CRUD operations.
/// - Typed endpoint helpers for orders, payments, media, and reports.
///
/// Usage:
/// ```dart
/// final client = NestJSClient(baseUrl: 'https://api.omnigo.vn');
/// final response = await client.get('/products', queryParams: {'page': 1});
/// ```
class NestJSClient {
  late final Dio _dio;

  /// Creates a new [NestJSClient].
  ///
  /// - [baseUrl] : Root URL of the NestJS backend (e.g. `https://api.omnigo.vn`).
  /// - [authToken] : Optional initial bearer token. If omitted, the
  ///   [AuthInterceptor] will pull the current Supabase JWT automatically.
  /// - [connectTimeout] : Connection timeout duration.
  /// - [receiveTimeout] : Response receive timeout duration.
  NestJSClient({
    required String baseUrl,
    String? authToken,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );

    // Order matters: auth first, then logging, then error mapping.
    _dio.interceptors.addAll([
      AuthInterceptor(),
      _loggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// Exposes the underlying [Dio] instance for advanced use cases.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  /// Manually sets (or replaces) the bearer token on all future requests.
  ///
  /// Normally this is unnecessary because [AuthInterceptor] reads the
  /// Supabase session automatically. Use this only if you need to override
  /// the token (e.g., for testing).
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes the manually-set bearer token, falling back to [AuthInterceptor].
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ---------------------------------------------------------------------------
  // Generic CRUD
  // ---------------------------------------------------------------------------

  /// Sends a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
  }

  /// Sends a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
  }

  /// Sends a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
  }

  /// Sends a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
  }

  /// Sends a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
  }

  // ---------------------------------------------------------------------------
  // Domain-specific endpoints
  // ---------------------------------------------------------------------------

  /// Creates a new order.
  Future<Response<dynamic>> createOrder(Map<String, dynamic> orderData) {
    return post('orders', data: orderData);
  }

  /// Creates a payment record for an order.
  Future<Response<dynamic>> createPayment(
      Map<String, dynamic> paymentData) {
    return post('payments', data: paymentData);
  }

  /// Uploads a media file (image, document, etc.) via multipart form data.
  ///
  /// - [filePath] : Absolute path to the local file.
  /// - [field] : Form field name expected by the server. Defaults to `'file'`.
  Future<Response<dynamic>> uploadMedia(
    String filePath, {
    String field = 'file',
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath),
    });

    return _dio.post(
      'media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress,
    );
  }

  /// Retrieves a report of the given [type].
  ///
  /// Common report types: `'sales'`, `'inventory'`, `'revenue'`.
  Future<Response<dynamic>> getReport(
    String type,
    Map<String, dynamic> params,
  ) {
    return get('reports/$type', queryParams: params);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Lightweight request/response logger (debug builds only).
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        developer.log(
          '--> ${options.method} ${options.uri}',
          name: 'api_client',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log(
          '<-- ${response.statusCode} ${response.requestOptions.uri}',
          name: 'api_client',
        );
        handler.next(response);
      },
      onError: (err, handler) {
        developer.log(
          '<-- ERROR ${err.response?.statusCode ?? 'N/A'} '
          '${err.requestOptions.uri}',
          name: 'api_client',
          level: 1000,
        );
        handler.next(err);
      },
    );
  }
}
