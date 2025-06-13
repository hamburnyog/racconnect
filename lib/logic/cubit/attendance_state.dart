part of 'attendance_cubit.dart';

sealed class AttendanceState {
  const AttendanceState();
}

final class AttendanceInitial extends AttendanceState {}

final class AttendanceLoading extends AttendanceState {}

final class AttendanceError extends AttendanceState {
  final String error;
  const AttendanceError(this.error);
}

final class AttendanceAddSuccess extends AttendanceState {
  final AttendanceModel attendanceModel;
  const AttendanceAddSuccess(this.attendanceModel);
}

final class GetAllAttendanceSuccess extends AttendanceState {
  final List<AttendanceModel> events;
  const GetAllAttendanceSuccess(this.events);
}

final class GetEmployeeAttendanceSuccess extends AttendanceState {
  final List<AttendanceModel> attendanceModels;
  const GetEmployeeAttendanceSuccess(this.attendanceModels);
}
