part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSignedUp extends AuthState {}

final class AuthPasswordResetSent extends AuthState {}

final class AuthSignedIn extends AuthState {
  final UserModel user;
  AuthSignedIn(this.user);
}

final class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
