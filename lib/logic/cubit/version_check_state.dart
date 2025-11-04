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
  final String? iosLink;
  final String? androidLink;
  final String? macLink;
  final String? windowsLink;

  const VersionCheckOutdated({
    required this.publishedVersion,
    this.iosLink,
    this.androidLink,
    this.macLink,
    this.windowsLink,
  });

  @override
  List<Object> get props => [
    publishedVersion,
    iosLink ?? '',
    androidLink ?? '',
    macLink ?? '',
    windowsLink ?? ''
  ];
}

class VersionCheckError extends VersionCheckState {
  final String error;

  const VersionCheckError({required this.error});

  @override
  List<Object> get props => [error];
}
