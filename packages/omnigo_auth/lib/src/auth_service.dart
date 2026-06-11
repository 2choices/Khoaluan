import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class wrapping Supabase Auth (GoTrueClient).
///
/// Provides a clean API for authentication operations including email/password,
/// phone OTP, social logins (Google, Apple), password reset, and profile updates.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Convenience getter for the GoTrue auth client.
  GoTrueClient get _auth => _client.auth;

  // ---------------------------------------------------------------------------
  // Streams & getters
  // ---------------------------------------------------------------------------

  /// Stream of auth state changes (sign in, sign out, token refresh, etc.).
  Stream<AuthState> get onAuthStateChange =>
      _auth.onAuthStateChange;

  /// The currently signed-in user, or `null`.
  User? get currentUser => _auth.currentUser;

  /// The current session, or `null`.
  Session? get currentSession => _auth.currentSession;

  /// Whether a user is currently authenticated with a valid session.
  bool get isAuthenticated => currentSession != null;

  // ---------------------------------------------------------------------------
  // Email / Password
  // ---------------------------------------------------------------------------

  /// Sign in with email and password.
  ///
  /// Throws [AuthException] on failure.
  Future<AuthResponse> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  /// Create a new account with email and password.
  ///
  /// Optionally pass [fullName] to store in user metadata.
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-up failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Phone / OTP
  // ---------------------------------------------------------------------------

  /// Send an OTP to the given phone number.
  ///
  /// After calling this, use [verifyOTP] to complete authentication.
  Future<AuthResponse> signInWithPhone(String phone) async {
    try {
      await _auth.signInWithOtp(phone: phone);
      // signInWithOtp returns void; return a stub AuthResponse.
      // The actual AuthResponse comes from verifyOTP.
      return AuthResponse(session: null, user: null);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Phone sign-in failed: $e');
    }
  }

  /// Verify the OTP [token] sent to [phone].
  Future<AuthResponse> verifyOTP(String phone, String token) async {
    try {
      return await _auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('OTP verification failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Social / OAuth
  // ---------------------------------------------------------------------------

  /// Sign in with Google via OAuth.
  ///
  /// On mobile this opens a browser; on web it redirects.
  /// Returns an [AuthResponse] after the OAuth flow completes.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final result = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirectUrl,
      );
      if (!result) {
        throw const AuthException('Google sign-in was cancelled or failed.');
      }
      // OAuth redirects back – the session is picked up via onAuthStateChange.
      // Return current state; the caller should listen to the stream.
      return AuthResponse(
        session: _auth.currentSession,
        user: _auth.currentUser,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Sign in with Apple via OAuth.
  Future<AuthResponse> signInWithApple() async {
    try {
      final result = await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _oauthRedirectUrl,
      );
      if (!result) {
        throw const AuthException('Apple sign-in was cancelled or failed.');
      }
      return AuthResponse(
        session: _auth.currentSession,
        user: _auth.currentUser,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Sign out the current user (local + remote).
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-out failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  /// Send a password-reset email to [email].
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Password reset failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Update the current user's profile metadata.
  Future<UserResponse> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      return await _auth.updateUser(
        UserAttributes(data: data),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Profile update failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  /// Attempt to refresh the current session.
  ///
  /// Returns the new [Session] or `null` if refresh failed.
  Future<Session?> refreshSession() async {
    try {
      final response = await _auth.refreshSession();
      return response.session;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Session refresh failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Default OAuth redirect URL.
  ///
  /// Adjust this to match your app's deep-link / redirect configuration.
  String? get _oauthRedirectUrl => null;
}
