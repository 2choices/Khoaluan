/// OMNIGO API Client Package
///
/// Provides a unified API layer for communicating with both the
/// Supabase backend (auth, database, realtime, storage) and the
/// NestJS REST API (orders, payments, media, reports).
library;

// Exceptions
export 'src/exceptions.dart';

// Interceptors
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/error_interceptor.dart';

// Clients
export 'src/nestjs_client.dart';
export 'src/supabase_client_provider.dart';
