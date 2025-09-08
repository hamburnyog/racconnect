import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/data/repositories/travel_repository.dart';

part 'travel_state.dart';

class TravelCubit extends Cubit<TravelState> {
  TravelCubit() : super(TravelInitial());
  final TravelRepository travelRepository = TravelRepository();

  Future<void> addTravel({
    required String soNumber,
    required List<String> employeeNumbers,
    required List<DateTime> specificDates,
  }) async {
    try {
      emit(TravelLoading());
      final travelModel = await travelRepository.addTravel(
        soNumber: soNumber,
        employeeNumbers: employeeNumbers,
        specificDates: specificDates,
      );
      emit(TravelAddSuccess(travelModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> updateTravel({
    required String id,
    required String soNumber,
    required List<String> employeeNumbers,
    required List<DateTime> specificDates,
  }) async {
    try {
      emit(TravelLoading());
      final travelModel = await travelRepository.updateTravel(
        id: id,
        soNumber: soNumber,
        employeeNumbers: employeeNumbers,
        specificDates: specificDates,
      );
      emit(TravelUpdateSuccess(travelModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> deleteTravel({required String id}) async {
    try {
      emit(TravelLoading());
      await travelRepository.deleteTravel(id: id);
      emit(TravelDeleteSuccess());
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllTravels() async {
    try {
      emit(TravelLoading());
      final travelModels = await travelRepository.getAllTravels();
      emit(GetAllTravelSuccess(travelModels));
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
          data['soNumber'] != null &&
          data['soNumber']['code'] == 'validation_not_unique') {
        emit(TravelError('The special order number is already taken.'));
      } else {
        emit(TravelError(message?.toString() ?? 'Unknown error'));
      }
    } else {
      emit(TravelError(e.toString()));
    }
  }
}
