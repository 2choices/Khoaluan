part of 'auth_cubit.dart';

enum CustomerAuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpRequired,
  error,
}

class CustomerAuthState {
  final CustomerAuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? pendingEmail;
  final String? pendingPassword;
  final String? pendingFullName;

  const CustomerAuthState({
    this.status = CustomerAuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingEmail,
    this.pendingPassword,
    this.pendingFullName,
  });

  static const _unset = Object();

  CustomerAuthState copyWith({
    CustomerAuthStatus? status,
    Object? user = _unset,
    Object? errorMessage = _unset,
    Object? pendingEmail = _unset,
    Object? pendingPassword = _unset,
    Object? pendingFullName = _unset,
  }) {
    return CustomerAuthState(
      status: status ?? this.status,
      user: user == _unset ? this.user : user as User?,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      pendingEmail:
          pendingEmail == _unset ? this.pendingEmail : pendingEmail as String?,
      pendingPassword: pendingPassword == _unset
          ? this.pendingPassword
          : pendingPassword as String?,
      pendingFullName: pendingFullName == _unset
          ? this.pendingFullName
          : pendingFullName as String?,
    );
  }
}
