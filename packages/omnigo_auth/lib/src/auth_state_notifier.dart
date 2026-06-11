import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Represents the current authentication status.
enum AuthStatus {
  /// Initial state, auth status has not been determined yet.
  initial,

  /// User is authenticated and session is valid.
  authenticated,

  /// User is not authenticated or session has expired.
  unauthenticated,

  /// An authentication operation is in progress.
  loading,

  /// An error occurred during authentication.
  error,
}

/// A simple holder for authentication state.
///
/// This can be used by state management solutions (Riverpod, Bloc, etc.)
/// to track the current auth status, user, and any error messages.
class AuthStateNotifier {
  AuthStatus status;
  User? user;
  String? errorMessage;

  AuthStateNotifier({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether an auth operation is in progress.
  bool get isLoading => status == AuthStatus.loading;

  /// Whether there is an error.
  bool get hasError => status == AuthStatus.error && errorMessage != null;

  /// Transition to loading state.
  void setLoading() {
    status = AuthStatus.loading;
    errorMessage = null;
  }

  /// Transition to authenticated state.
  void setAuthenticated(User user) {
    status = AuthStatus.authenticated;
    this.user = user;
    errorMessage = null;
  }

  /// Transition to unauthenticated state.
  void setUnauthenticated() {
    status = AuthStatus.unauthenticated;
    user = null;
    errorMessage = null;
  }

  /// Transition to error state.
  void setError(String message) {
    status = AuthStatus.error;
    errorMessage = message;
  }

  /// Reset to initial state.
  void reset() {
    status = AuthStatus.initial;
    user = null;
    errorMessage = null;
  }

  @override
  String toString() =>
      'AuthStateNotifier(status: $status, user: ${user?.id}, error: $errorMessage)';
}
