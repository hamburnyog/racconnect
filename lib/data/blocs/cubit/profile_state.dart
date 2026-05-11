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

final class SaveProfileSuccess extends ProfileState {
  final ProfileModel profile;
  const SaveProfileSuccess(this.profile);
}

final class GetProfileSuccess extends ProfileState {}

final class GetAllProfilesSuccess extends ProfileState {
  final List<ProfileModel> profiles;
  const GetAllProfilesSuccess(this.profiles);
}
