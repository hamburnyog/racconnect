import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';

part 'accomplishment_state.dart';

class AccomplishmentCubit extends Cubit<AccomplishmentState> {
  final _accomplishmentRepository = AccomplishmentRepository();

  AccomplishmentCubit() : super(AccomplishmentInitial());

  void fetchAccomplishments() async {
    emit(AccomplishmentLoading());
    try {
      final accomplishments =
          await _accomplishmentRepository.getAccomplishments();
      emit(AccomplishmentLoaded(accomplishments));
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      emit(AccomplishmentError(e.response['message'].toString()));
    } else {
      emit(AccomplishmentError(e.toString()));
    }
  }
}
