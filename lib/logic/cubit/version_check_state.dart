part of 'version_check_cubit.dart';

abstract class VersionCheckState extends Equatable {
  const VersionCheckState();

  @override
  List<Object> get props => [];
}

class VersionCheckInitial extends VersionCheckState {}

class VersionCheckLoading extends VersionCheckState {}

class VersionCheckUpToDate extends VersionCheckState {}

class VersionCheckOutdated extends VersionCheckState {
  final String publishedVersion;
  final String? driveLink;

  const VersionCheckOutdated({required this.publishedVersion, this.driveLink});

  @override
  List<Object> get props => [publishedVersion, driveLink ?? ''];
}

class VersionCheckError extends VersionCheckState {
  final String error;

  const VersionCheckError({required this.error});

  @override
  List<Object> get props => [error];
}
