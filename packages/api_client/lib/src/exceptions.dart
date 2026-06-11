/// Custom exception classes for the OMNIGO API Client.
library;

/// Base API exception class.
class ApiException implements Exception {
  /// HTTP status code, if available.
  final int? statusCode;

  /// Human-readable error message.
  final String message;

  /// Original error that caused this exception.
  final dynamic originalError;

  const ApiException({
    this.statusCode,
    this.message = 'An unexpected API error occurred',
    this.originalError,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

/// Thrown when a network error occurs (no internet, timeout, DNS failure, etc.).
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network error. Please check your internet connection.',
    super.originalError,
  }) : super(statusCode: null);

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Thrown when the server responds with 401 Unauthorized.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Unauthorized. Please sign in again.',
    super.originalError,
  }) : super(statusCode: 401);

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}

/// Thrown when the server responds with 403 Forbidden.
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.originalError,
  }) : super(statusCode: 403);

  @override
  String toString() => 'ForbiddenException(message: $message)';
}

/// Thrown when the server responds with 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.originalError,
  }) : super(statusCode: 404);

  @override
  String toString() => 'NotFoundException(message: $message)';
}

/// Thrown when the server responds with 409 Conflict.
class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'A conflict occurred with the current state of the resource.',
    super.originalError,
  }) : super(statusCode: 409);

  @override
  String toString() => 'ConflictException(message: $message)';
}

/// Thrown when the server responds with 422 Unprocessable Entity.
class ValidationException extends ApiException {
  /// Field-level validation errors, if provided by the server.
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    super.message = 'Validation failed. Please check your input.',
    super.originalError,
    this.fieldErrors,
  }) : super(statusCode: 422);

  @override
  String toString() =>
      'ValidationException(message: $message, fieldErrors: $fieldErrors)';
}

/// Thrown when the server responds with 429 Too Many Requests.
class RateLimitException extends ApiException {
  /// Number of seconds before the client should retry.
  final int? retryAfterSeconds;

  const RateLimitException({
    super.message = 'Too many requests. Please try again later.',
    super.originalError,
    this.retryAfterSeconds,
  }) : super(statusCode: 429);

  @override
  String toString() =>
      'RateLimitException(message: $message, retryAfter: ${retryAfterSeconds}s)';
}

/// Thrown when the server responds with 5xx Server Error.
class ServerException extends ApiException {
  const ServerException({
    super.statusCode = 500,
    super.message = 'An internal server error occurred. Please try again later.',
    super.originalError,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message)';
}

/// Thrown when a request is cancelled.
class RequestCancelledException extends ApiException {
  const RequestCancelledException({
    super.message = 'The request was cancelled.',
    super.originalError,
  }) : super(statusCode: null);

  @override
  String toString() => 'RequestCancelledException(message: $message)';
}

/// Thrown when a request times out.
class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'The request timed out. Please try again.',
    super.originalError,
  }) : super(statusCode: null);

  @override
  String toString() => 'TimeoutException(message: $message)';
}
