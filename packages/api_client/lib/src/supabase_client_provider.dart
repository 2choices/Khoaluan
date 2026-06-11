import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper for Supabase initialization and access.
///
/// Provides a single point of access to the Supabase client instance
/// and convenience getters for commonly used services (auth, tables, channels).
///
/// Usage:
/// ```dart
/// // Initialize once at app startup
/// await SupabaseClientProvider.initialize(
///   url: 'https://your-project.supabase.co',
///   anonKey: 'your-anon-key',
/// );
///
/// // Access the client anywhere
/// final user = SupabaseClientProvider.auth.currentUser;
/// final data = await SupabaseClientProvider.table('products').select();
/// ```
class SupabaseClientProvider {
  SupabaseClientProvider._();

  static bool _initialized = false;

  /// Returns the Supabase client instance.
  ///
  /// Throws [StateError] if [initialize] has not been called.
  static SupabaseClient get client {
    _assertInitialized();
    return Supabase.instance.client;
  }

  /// Initializes the Supabase client.
  ///
  /// Must be called exactly once before any other access, typically
  /// in `main()` before `runApp()`.
  ///
  /// - [url] : The Supabase project URL.
  /// - [anonKey] : The Supabase anonymous (public) API key.
  /// - [debug] : If `true`, enables Supabase debug logging.
  static Future<void> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    if (_initialized) {
      developer.log(
        'SupabaseClientProvider already initialized – skipping.',
        name: 'api_client',
      );
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
    );

    _initialized = true;
    developer.log(
      'Supabase initialized successfully for $url',
      name: 'api_client',
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// Shortcut to the GoTrue authentication client.
  static GoTrueClient get auth {
    _assertInitialized();
    return client.auth;
  }

  /// Returns a [SupabaseQueryBuilder] for the given [name] table.
  static SupabaseQueryBuilder table(String name) {
    _assertInitialized();
    return client.from(name);
  }

  /// Returns a [RealtimeChannel] for the given [name].
  static RealtimeChannel channel(String name) {
    _assertInitialized();
    return client.channel(name);
  }

  /// Returns the Supabase storage client.
  static SupabaseStorageClient get storage {
    _assertInitialized();
    return client.storage;
  }

  /// Returns the Supabase Functions (Edge Functions) client.
  static FunctionsClient get functions {
    _assertInitialized();
    return client.functions;
  }

  /// Returns the current user's JWT access token, or `null` if not signed in.
  static String? get currentAccessToken {
    _assertInitialized();
    return client.auth.currentSession?.accessToken;
  }

  /// Whether the client has been initialized.
  static bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'SupabaseClientProvider has not been initialized. '
        'Call SupabaseClientProvider.initialize() first.',
      );
    }
  }
}
