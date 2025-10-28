import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:racconnect/services/version_check_service.dart';

part 'version_check_state.dart';

class VersionCheckCubit extends Cubit<VersionCheckState> {
  final VersionCheckService _versionCheckService;

  VersionCheckCubit({required VersionCheckService versionCheckService})
    : _versionCheckService = versionCheckService,
      super(VersionCheckInitial());

  Future<void> checkVersion() async {
    emit(VersionCheckLoading());

    try {
      final result = await _versionCheckService.checkVersion();

      if (result.isOutdated) {
        emit(
          VersionCheckOutdated(
            publishedVersion: result.publishedVersion,
            driveLink: result.driveLink,
          ),
        );
      } else {
        emit(VersionCheckUpToDate());
      }
    } catch (e) {
      emit(VersionCheckError(error: e.toString()));
    }
  }

  void dismissNotification() {
    if (state is VersionCheckOutdated) {
      emit(VersionCheckUpToDate());
    }
  }
}
