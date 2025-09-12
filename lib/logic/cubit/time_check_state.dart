part of 'time_check_cubit.dart';

abstract class TimeCheckState {}

class TimeCheckInitial extends TimeCheckState {}

class TimeValid extends TimeCheckState {}

class TimeTampered extends TimeCheckState {
  final Duration timeDifference;
  final bool localTimeAhead;

  TimeTampered({
    required this.timeDifference,
    required this.localTimeAhead,
  });
}