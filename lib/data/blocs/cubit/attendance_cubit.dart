import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';

part 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit() : super(AttendanceInitial());
  final AttendanceRepository attendanceRepository = AttendanceRepository();

  Future<void> getAllAttendances() async {
    try {
      emit(AttendanceLoading());
      final attendanceModels = await attendanceRepository.getAllAttendanceForMonth(DateTime.now());
      emit(GetAllAttendanceSuccess(attendanceModels));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllAttendanceForMonth(DateTime monthDate) async {
    try {
      emit(AttendanceLoading());
      final attendanceModels = await attendanceRepository.getAllAttendanceForMonth(monthDate);
      emit(GetAllAttendanceSuccess(attendanceModels));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getEmployeeAttendance({String? employeeNumber}) async {
    try {
      emit(AttendanceLoading());
      final attendanceModel = await attendanceRepository.getEmployeeAttendance(
        employeeNumber,
      );
      emit(GetEmployeeAttendanceSuccess(attendanceModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getEmployeeAttendanceToday({String? employeeNumber}) async {
    try {
      emit(AttendanceLoading());
      final attendanceModel = await attendanceRepository
          .getEmployeeAttendanceToday(employeeNumber);
      emit(GetTodayAttendanceSuccess(attendanceModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getEmployeeAttendanceForMonth({
    required String employeeNumber,
    required DateTime monthDate,
  }) async {
    try {
      emit(AttendanceLoading());
      final attendanceModel = await attendanceRepository
          .getEmployeeAttendanceForMonth(employeeNumber, monthDate);
      emit(GetEmployeeAttendanceSuccess(attendanceModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> addAttendance({
    required String employeeNumber,
    required String remarks,
    String? accomplishmentId,
  }) async {
    try {
      emit(AttendanceLoading());
      final attendanceModel = await attendanceRepository.addAttendance(
        employeeNumber: employeeNumber,
        timestamp: DateTime.parse(DateTime.now().toIso8601String()),
        remarks: remarks,
        accomplishmentId: accomplishmentId,
      );
      emit(AttendanceAddSuccess(attendanceModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> uploadAttendance({
    required String employeeNumber,
    required DateTime timestamp,
  }) async {
    try {
      emit(AttendanceLoading());
      final attendance = await attendanceRepository.uploadAttendance(
        employeeNumber: employeeNumber,
        timestamp: timestamp,
      );
      emit(AttendanceAddSuccess(attendance));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> updateAttendance({
    required String id,
    required DateTime timestamp,
    String? remarks,
  }) async {
    try {
      emit(AttendanceLoading());
      final attendance = await attendanceRepository.updateAttendance(
        id: id,
        timestamp: timestamp,
        remarks: remarks,
      );
      emit(AttendanceAddSuccess(attendance));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> deleteAttendance(String id) async {
    try {
      emit(AttendanceLoading());
      await attendanceRepository.deleteAttendance(id);
      emit(AttendanceInitial()); // Or a success state if needed
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      final message = e.response?['message'];
      emit(AttendanceError(message?.toString() ?? 'Unknown error'));
    } else {
      emit(AttendanceError(e.toString()));
    }
  }
}
