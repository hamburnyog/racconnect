part of 'profile_cubit.dart';

sealed class ProfileState {
  const ProfileState();
}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileError extends ProfileState {
  final String error;
  const ProfileError(this.error);
}

final class SaveProfileSuccess extends ProfileState {}

final class GetProfileSuccess extends ProfileState {}
