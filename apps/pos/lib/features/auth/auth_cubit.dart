import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:api_client/api_client.dart';

part 'auth_state.dart';

class PosAuthCubit extends Cubit<PosAuthState> {
  final SupabaseClient _supabase;
  final NestJSClient api;

  PosAuthCubit(this._supabase, this.api) : super(const PosAuthState());

  void checkAuth() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      emit(state.copyWith(
        status: PosAuthStatus.authenticated,
        user: _supabase.auth.currentUser,
      ));
    } else {
      emit(state.copyWith(status: PosAuthStatus.unauthenticated));
    }

    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        emit(state.copyWith(
          status: PosAuthStatus.authenticated,
          user: data.session?.user,
        ));
      } else if (data.event == AuthChangeEvent.signedOut) {
        emit(state.copyWith(
          status: PosAuthStatus.unauthenticated,
          user: null,
        ));
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(status: PosAuthStatus.loading));
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      emit(state.copyWith(
        status: PosAuthStatus.authenticated,
        user: response.user,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: PosAuthStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PosAuthStatus.error,
        errorMessage: 'Đăng nhập thất bại',
      ));
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    emit(state.copyWith(status: PosAuthStatus.unauthenticated, user: null));
  }
}
