part of 'holiday_cubit.dart';

sealed class HolidayState {
  const HolidayState();
}

final class HolidayInitial extends HolidayState {}

final class HolidayLoading extends HolidayState {}

final class HolidayError extends HolidayState {
  final String error;
  const HolidayError(this.error);
}

final class GetAllHolidaySuccess extends HolidayState {
  final List<HolidayModel> holidayModels;
  final List<HolidayModel> filteredHolidayModels;
  final int selectedYear;
  const GetAllHolidaySuccess(
      this.holidayModels, this.filteredHolidayModels, this.selectedYear);
}

final class HolidayAddSuccess extends HolidayState {
  final HolidayModel holidayModel;
  const HolidayAddSuccess(this.holidayModel);
}

final class HolidayUpdateSuccess extends HolidayState {
  final HolidayModel holidayModel;
  const HolidayUpdateSuccess(this.holidayModel);
}

final class HolidayDeleteSuccess extends HolidayState {}
