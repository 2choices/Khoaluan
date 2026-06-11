import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';

import '../exceptions.dart';

/// Dio interceptor that maps HTTP error responses and Dio errors
/// to typed [ApiException] subclasses.
///
/// This allows the rest of the app to catch specific exception types
/// (e.g., [UnauthorizedException]) instead of inspecting raw status codes.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _mapDioException(err);

    developer.log(
      'API Error: $apiException',
      name: 'api_client',
      level: 1000, // SEVERE
      error: err,
    );

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  /// Maps a [DioException] to an appropriate [ApiException] subclass.
  ApiException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: err);

      case DioExceptionType.cancel:
        return RequestCancelledException(originalError: err);

      case DioExceptionType.connectionError:
        return NetworkException(originalError: err);

      case DioExceptionType.badResponse:
        return _mapHttpStatus(err);

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'Certificate verification failed.',
        );

      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          return NetworkException(originalError: err);
        }
        return ApiException(
          message: err.message ?? 'An unknown error occurred',
          originalError: err,
        );
    }
  }

  /// Maps an HTTP status code to a specific [ApiException] subclass.
  ApiException _mapHttpStatus(DioException err) {
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;

    // Try to extract a server-provided message.
    final serverMessage = _extractServerMessage(responseData);

    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Unauthorized. Please sign in again.',
          originalError: err,
        );

      case 403:
        return ForbiddenException(
          message: serverMessage ??
              'You do not have permission to perform this action.',
          originalError: err,
        );

      case 404:
        return NotFoundException(
          message: serverMessage ?? 'The requested resource was not found.',
          originalError: err,
        );

      case 409:
        return ConflictException(
          message: serverMessage ??
              'A conflict occurred with the current state of the resource.',
          originalError: err,
        );

      case 422:
        return ValidationException(
          message: serverMessage ?? 'Validation failed.',
          fieldErrors: _extractFieldErrors(responseData),
          originalError: err,
        );

      case 429:
        final retryAfter = _extractRetryAfter(err.response);
        return RateLimitException(
          message: serverMessage ?? 'Too many requests. Please try again later.',
          retryAfterSeconds: retryAfter,
          originalError: err,
        );

      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            statusCode: statusCode,
            message: serverMessage ?? 'Internal server error.',
            originalError: err,
          );
        }
        return ApiException(
          statusCode: statusCode,
          message: serverMessage ?? 'HTTP error $statusCode',
          originalError: err,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Response body parsing helpers
  // ---------------------------------------------------------------------------

  /// Attempts to pull a human-readable message from the response body.
  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      // NestJS default error shape: { message, statusCode, error }
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List && msg.isNotEmpty) return msg.first.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  /// Extracts field-level validation errors for 422 responses.
  Map<String, List<String>>? _extractFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    // NestJS class-validator shape: { message: ['field must be ...', ...] }
    final msg = data['message'];
    if (msg is List) {
      final errors = <String, List<String>>{};
      for (final item in msg) {
        if (item is Map<String, dynamic>) {
          final property = item['property'] as String?;
          final constraints = item['constraints'];
          if (property != null && constraints is Map) {
            errors[property] = constraints.values
                .map((v) => v.toString())
                .toList(growable: false);
          }
        } else if (item is String) {
          errors.putIfAbsent('_general', () => []).add(item);
        }
      }
      if (errors.isNotEmpty) return errors;
    }

    // Fallback: { errors: { field: ['...'] } }
    final errorsMap = data['errors'];
    if (errorsMap is Map<String, dynamic>) {
      return errorsMap.map(
        (key, value) => MapEntry(
          key,
          value is List
              ? value.map((e) => e.toString()).toList(growable: false)
              : [value.toString()],
        ),
      );
    }

    return null;
  }

  /// Extracts `Retry-After` header value (in seconds).
  int? _extractRetryAfter(Response? response) {
    final header = response?.headers.value('retry-after');
    if (header == null) return null;
    return int.tryParse(header);
  }
}
