import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/data/repositories/signatory_repository.dart';

part 'signatory_state.dart';

class SignatoryCubit extends Cubit<SignatoryState> {
  final SignatoryRepository signatoryRepository;

  SignatoryCubit(this.signatoryRepository) : super(SignatoryInitial());

  Future<void> getSignatories() async {
    try {
      emit(SignatoryLoading());
      final signatories = await signatoryRepository.getSignatories();
      emit(SignatoryLoadSuccess(signatories));
    } catch (e) {
      emit(SignatoryError(e.toString()));
    }
  }

  Future<void> getSignatoriesBySection(String sectionId) async {
    try {
      emit(SignatoryLoading());
      final signatories = await signatoryRepository.getSignatoriesBySection(sectionId);
      emit(SignatoryLoadSuccess(signatories));
    } catch (e) {
      emit(SignatoryError(e.toString()));
    }
  }

  Future<void> addSignatory(SignatoryModel signatory) async {
    try {
      emit(SignatoryLoading());
      await signatoryRepository.addSignatory(signatory);
      await getSignatories();
    } catch (e) {
      emit(SignatoryError(e.toString()));
    }
  }

  Future<void> updateSignatory(SignatoryModel signatory) async {
    try {
      emit(SignatoryLoading());
      await signatoryRepository.updateSignatory(signatory);
      await getSignatories();
    } catch (e) {
      emit(SignatoryError(e.toString()));
    }
  }

  Future<void> deleteSignatory(String id) async {
    try {
      emit(SignatoryLoading());
      await signatoryRepository.deleteSignatory(id);
      await getSignatories();
    } catch (e) {
      emit(SignatoryError(e.toString()));
    }
  }
}
