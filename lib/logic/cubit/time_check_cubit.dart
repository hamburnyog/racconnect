import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntp/ntp.dart';

part 'time_check_state.dart';

class TimeCheckCubit extends Cubit<TimeCheckState> {
  Timer? _timer;
  static const int _checkIntervalSeconds = 3;
  static const int _toleranceSeconds = 180;

  TimeCheckCubit() : super(TimeCheckInitial()) {
    startChecking();
  }

  void startChecking() {
    // Immediately check on start
    _checkTime();

    // Then check every 5 seconds
    _timer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkTime(),
    );
  }

  Future<void> _checkTime() async {
    try {
      // Get time from NTP server
      final int ntpTime = await NTP.getNtpOffset();
      final Duration timeDifference = Duration(milliseconds: ntpTime.abs());

      // Check if time difference exceeds tolerance
      if (timeDifference.inSeconds > _toleranceSeconds) {
        emit(
          TimeTampered(
            timeDifference: timeDifference,
            localTimeAhead: ntpTime < 0,
          ),
        );
      } else {
        emit(TimeValid());
      }
    } catch (e) {
      // If we can't reach the NTP server, we don't want to falsely
      // accuse the user of tampering, so we'll assume time is valid
      emit(TimeValid());
    }
  }

  void stopChecking() {
    _timer?.cancel();
  }

  @override
  Future<void> close() {
    stopChecking();
    return super.close();
  }
}
