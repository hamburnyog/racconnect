import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/data/repositories/suspension_repository.dart';

part 'suspension_state.dart';

class SuspensionCubit extends Cubit<SuspensionState> {
  SuspensionCubit() : super(SuspensionInitial());
  final SuspensionRepository suspensionRepository = SuspensionRepository();

  Future<void> addSuspension({
    required String name,
    required DateTime datetime,
    required bool isHalfday,
  }) async {
    try {
      emit(SuspensionLoading());
      final suspensionModel = await suspensionRepository.addSuspension(
        name: name,
        datetime: datetime,
        isHalfday: isHalfday,
      );
      emit(SuspensionAddSuccess(suspensionModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> updateSuspension({
    required String id,
    required String name,
    required DateTime datetime,
    required bool isHalfday,
  }) async {
    try {
      emit(SuspensionLoading());
      final suspensionModel = await suspensionRepository.updateSuspension(
        id: id,
        name: name,
        datetime: datetime,
        isHalfday: isHalfday,
      );
      emit(SuspensionUpdateSuccess(suspensionModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> deleteSuspension({required String id}) async {
    try {
      emit(SuspensionLoading());
      await suspensionRepository.deleteSuspension(id: id);
      emit(SuspensionDeleteSuccess());
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllSuspensions({String? employeeNumber}) async {
    try {
      emit(SuspensionLoading());
      final suspensionModel = await suspensionRepository.getAllSuspensions(
        employeeNumber,
      );
      emit(GetAllSuspensionSuccess(suspensionModel));
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
          data['name'] != null &&
          data['name']['code'] == 'validation_not_unique') {
        emit(SuspensionError('The name is already taken.'));
      } else {
        emit(SuspensionError(message?.toString() ?? 'Unknown error'));
      }
    } else {
      emit(SuspensionError(e.toString()));
    }
  }
}
