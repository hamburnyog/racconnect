import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntp/ntp.dart';

part 'time_check_state.dart';

class TimeCheckCubit extends Cubit<TimeCheckState> {
  DateTime? _lastNtpTime;
  Stopwatch? _stopwatch;
  Timer? _checkTimer;
  Timer? _syncTimer;
  static const int _checkIntervalSeconds = 5; // Check every 5 seconds for faster detection
  static const int _syncIntervalHours = 6; // Resync every 6 hours
  static const int _toleranceSeconds = 180;

  TimeCheckCubit() : super(TimeCheckInitial()) {
    // Initial sync and start checking
    _syncNtpTime();
    _startPeriodicChecks();
    _startPeriodicSync();
  }

  /// Sync with NTP server to get accurate time
  Future<void> _syncNtpTime() async {
    try {
      // Get time offset from NTP server
      final int ntpOffset = await NTP.getNtpOffset();
      
      // Calculate accurate time by applying offset to current time
      _lastNtpTime = DateTime.now().add(Duration(milliseconds: ntpOffset));
      
      // Start or reset stopwatch to track elapsed time since sync
      _stopwatch?.stop();
      _stopwatch = Stopwatch()..start();
      
      // Perform initial time check
      _checkTime();
    } catch (e) {
      // If we can't reach the NTP server, we don't want to falsely
      // accuse the user of tampering, so we'll assume time is valid
      emit(TimeValid());
    }
  }

  /// Get current accurate time using NTP + Stopwatch hybrid approach
  DateTime _getCurrentAccurateTime() {
    if (_lastNtpTime != null && _stopwatch != null) {
      // Calculate current time by adding elapsed stopwatch time to last NTP time
      return _lastNtpTime!.add(Duration(milliseconds: _stopwatch!.elapsedMilliseconds));
    }
    // Fallback to system time if NTP sync hasn't happened yet
    return DateTime.now();
  }

  /// Start periodic time checks
  void _startPeriodicChecks() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkTime(),
    );
  }

  /// Start periodic NTP resync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(hours: _syncIntervalHours),
      (_) => _syncNtpTime(),
    );
  }

  /// Check if device time has been tampered with
  Future<void> _checkTime() async {
    try {
      // Get accurate time using hybrid approach
      final DateTime accurateTime = _getCurrentAccurateTime();
      
      // Get current system time
      final DateTime systemTime = DateTime.now();
      
      // Calculate difference between accurate time and system time
      final Duration timeDifference = accurateTime.difference(systemTime).abs();
      
      // Check if time difference exceeds tolerance
      if (timeDifference.inSeconds > _toleranceSeconds) {
        emit(
          TimeTampered(
            timeDifference: timeDifference,
            localTimeAhead: systemTime.isAfter(accurateTime),
          ),
        );
      } else {
        emit(TimeValid());
      }
    } catch (e) {
      // If we encounter any errors, assume time is valid
      emit(TimeValid());
    }
  }

  /// Force immediate resync with NTP server
  Future<void> forceResync() async {
    await _syncNtpTime();
  }

  /// Stop all timers
  void stopChecking() {
    _checkTimer?.cancel();
    _syncTimer?.cancel();
    _stopwatch?.stop();
  }

  @override
  Future<void> close() {
    stopChecking();
    return super.close();
  }
}
