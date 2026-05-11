import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:racconnect/data/models/holiday_model.dart';
import 'package:racconnect/data/repositories/holiday_repository.dart';

part 'holiday_state.dart';

class HolidayCubit extends Cubit<HolidayState> {
  HolidayCubit() : super(HolidayInitial());
  final HolidayRepository holidayRepository = HolidayRepository();

  Future<void> addHoliday({
    required String name,
    required DateTime date,
  }) async {
    try {
      emit(HolidayLoading());
      final holidayModel = await holidayRepository.addHoliday(
        name: name,
        date: date,
      );
      emit(HolidayAddSuccess(holidayModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> updateHoliday({
    required String id,
    required String name,
    required DateTime date,
  }) async {
    try {
      emit(HolidayLoading());
      final holidayModel = await holidayRepository.updateHoliday(
        id: id,
        name: name,
        date: date,
      );
      emit(HolidayUpdateSuccess(holidayModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> deleteHoliday({required String id}) async {
    try {
      emit(HolidayLoading());
      await holidayRepository.deleteHoliday(id: id);
      emit(HolidayDeleteSuccess());
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllHolidays({int? year}) async {
    try {
      emit(HolidayLoading());
      final holidayModel = await holidayRepository.getAllHolidays();
      final selectedYear = year ?? DateTime.now().year;
      final filteredHolidays = holidayModel
          .where((holiday) => holiday.date.year == selectedYear)
          .toList();
      emit(GetAllHolidaySuccess(holidayModel, filteredHolidays, selectedYear));
    } catch (e) {
      errorMessage(e);
    }
  }

  void filterHolidaysByYear(int year) {
    if (state is GetAllHolidaySuccess) {
      final currentState = state as GetAllHolidaySuccess;
      final filteredHolidays = currentState.holidayModels
          .where((holiday) => holiday.date.year == year)
          .toList();
      emit(GetAllHolidaySuccess(
          currentState.holidayModels, filteredHolidays, year));
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
        emit(HolidayError('The name is already taken.'));
      } else {
        emit(HolidayError(message?.toString() ?? 'Unknown error'));
      }
    } else {
      emit(HolidayError(e.toString()));
    }
  }
}
