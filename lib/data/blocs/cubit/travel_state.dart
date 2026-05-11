part of 'travel_cubit.dart';

sealed class TravelState {
  const TravelState();
}

final class TravelInitial extends TravelState {}

final class TravelLoading extends TravelState {}

final class TravelError extends TravelState {
  final String error;
  const TravelError(this.error);
}

final class GetAllTravelSuccess extends TravelState {
  final List<TravelModel> travelModels;
  final List<TravelModel> filteredTravelModels;
  final int selectedYear;
  const GetAllTravelSuccess(
      this.travelModels, this.filteredTravelModels, this.selectedYear);
}

final class TravelAddSuccess extends TravelState {
  final TravelModel travelModel;
  const TravelAddSuccess(this.travelModel);
}

final class TravelUpdateSuccess extends TravelState {
  final TravelModel travelModel;
  const TravelUpdateSuccess(this.travelModel);
}

final class TravelDeleteSuccess extends TravelState {}
