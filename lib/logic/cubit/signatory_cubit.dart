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
}
