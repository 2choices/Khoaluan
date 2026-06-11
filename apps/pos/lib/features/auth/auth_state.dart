part of 'auth_cubit.dart';

enum PosAuthStatus { initial, loading, authenticated, unauthenticated, error }

class PosAuthState {
  final PosAuthStatus status;
  final User? user;
  final String? errorMessage;

  const PosAuthState({
    this.status = PosAuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  PosAuthState copyWith({
    PosAuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return PosAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
