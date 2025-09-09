import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/data/repositories/leave_repository.dart';

part 'leave_state.dart';

class LeaveCubit extends Cubit<LeaveState> {
  LeaveCubit() : super(LeaveInitial());
  final LeaveRepository leaveRepository = LeaveRepository();

  Future<void> addLeave({
    required String type,
    required List<DateTime> specificDates,
    required List<String> employeeNumbers,
  }) async {
    try {
      emit(LeaveLoading());
      final leaveModel = await leaveRepository.addLeave(
        type: type,
        specificDates: specificDates,
        employeeNumbers: employeeNumbers,
      );
      emit(LeaveAddSuccess(leaveModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> updateLeave({
    required String id,
    String? type,
    List<DateTime>? specificDates,
    List<String>? employeeNumbers,
  }) async {
    try {
      emit(LeaveLoading());
      final leaveModel = await leaveRepository.updateLeave(
        id: id,
        type: type,
        specificDates: specificDates,
        employeeNumbers: employeeNumbers,
      );
      emit(LeaveUpdateSuccess(leaveModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> deleteLeave({required String id}) async {
    try {
      emit(LeaveLoading());
      await leaveRepository.deleteLeave(id: id);
      emit(LeaveDeleteSuccess());
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllLeaves() async {
    try {
      emit(LeaveLoading());
      final leaveModels = await leaveRepository.getAllLeaves();
      emit(GetAllLeaveSuccess(leaveModels));
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      final data = e.response?['data'];
      final message = e.response?['message'];

      if (data != null &&
          data.isNotEmpty &&
          data['type'] != null &&
          data['type']['code'] == 'validation_not_unique') {
        emit(LeaveError('A similar leave already exists.'));
      } else {
        emit(LeaveError(message?.toString() ?? 'Unknown error'));
      }
    } else {
      emit(LeaveError(e.toString()));
    }
  }
}
