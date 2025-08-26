part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSignedUp extends AuthState {}

final class AuthPasswordResetSent extends AuthState {}

sealed class AuthenticatedState extends AuthState {
  final UserModel user;
  AuthenticatedState(this.user);
}

final class AuthSignedIn extends AuthenticatedState {
  AuthSignedIn(super.user);
}

final class UsersLoading extends AuthenticatedState {
  UsersLoading(super.user);
}

final class GetAllUsersSuccess extends AuthenticatedState {
  final List<UserModel> users;
  GetAllUsersSuccess(super.user, this.users);
}

final class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
