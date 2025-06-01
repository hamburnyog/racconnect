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
      final attendanceModels = await attendanceRepository.getAllAttendances();
      emit(GetAllAttendanceSuccess(attendanceModels));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> addAttendance({
    required String employeeNumber,
    required DateTime timestamp,
  }) async {
    try {
      emit(AttendanceLoading());
      final attendanceModel = await attendanceRepository.addAttendance(
        employeeNumber: employeeNumber,
        timestamp: timestamp,
        type: 'WFH',
      );
      emit(AttendanceAddSuccess(attendanceModel));
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
