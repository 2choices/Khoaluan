import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:api_client/api_client.dart';

part 'auth_state.dart';

class CustomerAuthCubit extends Cubit<CustomerAuthState> {
  final SupabaseClient _supabase;
  final NestJSClient api;

  CustomerAuthCubit(this._supabase, this.api) : super(const CustomerAuthState());

  String _extractErrorMessage(Object e, {String fallback = 'Đã xảy ra lỗi'}) {
    if (e is ApiException && e.message.isNotEmpty) {
      return e.message;
    }
    if (e is DioException) {
      final err = e.error;
      if (err is ApiException && err.message.isNotEmpty) {
        return err.message;
      }
      if (e.message != null && e.message!.trim().isNotEmpty) {
        return e.message!.trim();
      }
    }
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    return text.isNotEmpty ? text : fallback;
  }

  void checkAuth() {
    // Listen trước để không miss event
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.initialSession ||
          data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        if (data.session != null) {
          emit(state.copyWith(
            status: CustomerAuthStatus.authenticated,
            user: data.session?.user,
          ));
        } else {
          emit(state.copyWith(status: CustomerAuthStatus.unauthenticated));
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        emit(state.copyWith(
          status: CustomerAuthStatus.unauthenticated,
          user: null,
        ));
      }
    });

    // Fallback: nếu session đã có sẵn (native platforms)
    final session = _supabase.auth.currentSession;
    if (session != null) {
      emit(state.copyWith(
        status: CustomerAuthStatus.authenticated,
        user: _supabase.auth.currentUser,
      ));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(status: CustomerAuthStatus.loading));
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      emit(state.copyWith(
        status: CustomerAuthStatus.authenticated,
        user: response.user,
        pendingEmail: null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: 'Đăng nhập thất bại',
      ));
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    emit(state.copyWith(status: CustomerAuthStatus.loading));
    try {
      await api.post<dynamic>('/auth/signup-otp/send', data: {
        'email': email.trim().toLowerCase(),
      });

      emit(state.copyWith(
        status: CustomerAuthStatus.otpRequired,
        pendingEmail: email.trim().toLowerCase(),
        pendingPassword: password,
        pendingFullName: fullName.trim(),
        errorMessage: null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: _extractErrorMessage(e, fallback: 'Đăng ký thất bại'),
      ));
    }
  }

  Future<void> verifyEmailOtp(String email, String token) async {
    emit(state.copyWith(status: CustomerAuthStatus.loading));
    try {
      final pendingPassword = state.pendingPassword;
      final pendingFullName = state.pendingFullName;
      if (pendingPassword == null || pendingFullName == null) {
        emit(state.copyWith(
          status: CustomerAuthStatus.error,
          errorMessage: 'Phiên đăng ký đã hết. Vui lòng đăng ký lại.',
        ));
        return;
      }

      await api.post<dynamic>('/auth/signup-otp/verify', data: {
        'email': email.trim().toLowerCase(),
        'otp': token.trim(),
        'password': pendingPassword,
        'full_name': pendingFullName,
      });

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: pendingPassword,
      );

      emit(state.copyWith(
        status: CustomerAuthStatus.authenticated,
        user: response.user,
        pendingEmail: null,
        pendingPassword: null,
        pendingFullName: null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      final msg = _extractErrorMessage(e, fallback: 'Xác minh OTP thất bại');

      final lowerMsg = msg.toLowerCase();
      final canAutoLogin =
          lowerMsg.contains('đã được đăng ký') ||
          lowerMsg.contains('already registered');

      if (canAutoLogin) {
        try {
          final pendingPassword = state.pendingPassword;
          if (pendingPassword != null) {
            final response = await _supabase.auth.signInWithPassword(
              email: email.trim().toLowerCase(),
              password: pendingPassword,
            );
            emit(state.copyWith(
              status: CustomerAuthStatus.authenticated,
              user: response.user,
              pendingEmail: null,
              pendingPassword: null,
              pendingFullName: null,
            ));
            return;
          }
        } catch (_) {
          // fall through to emit original backend message
        }
      }

      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: msg,
      ));
    }
  }

  Future<void> resendSignUpOtp(String email) async {
    try {
      await api.post<dynamic>('/auth/signup-otp/send', data: {
        'email': email.trim().toLowerCase(),
      });
      emit(state.copyWith(
        status: CustomerAuthStatus.otpRequired,
        pendingEmail: email.trim().toLowerCase(),
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerAuthStatus.error,
        errorMessage: _extractErrorMessage(
          e,
          fallback: 'Không gửi lại được OTP',
        ),
      ));
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfile({required String fullName, String? phone}) async {
    // 1. Cập nhật Supabase Auth metadata (để user.userMetadata lên ngay)
    final response = await _supabase.auth.updateUser(
      UserAttributes(data: {
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    emit(state.copyWith(user: response.user));

    // 2. Đồng bộ về bảng customers (auto-create nếu chưa có) qua backend
    try {
      await api.patch<dynamic>('/customers/me', data: {
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
    } catch (_) {
      // backend chưa sẵn sàng — metadata vẫn đã update; bỏ qua
    }
  }

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    try {
      final res = await api.get<dynamic>('/customers/me');
      final raw = res.data;
      final data = (raw is Map && raw['data'] is Map) ? raw['data'] as Map : raw;
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    emit(state.copyWith(
      status: CustomerAuthStatus.unauthenticated,
      user: null,
      pendingEmail: null,
      pendingPassword: null,
      pendingFullName: null,
    ));
  }
}
