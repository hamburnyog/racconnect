import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/section_model.dart';
import 'package:racconnect/data/repositories/section_repository.dart';

part 'section_state.dart';

class SectionCubit extends Cubit<SectionState> {
  SectionCubit() : super(SectionInitial());
  final SectionRepository sectionRepository = SectionRepository();

  Future<void> addSection({required String name, required String code}) async {
    try {
      emit(SectionLoading());
      final sectionModel = await sectionRepository.addSection(
        name: name,
        code: code,
      );
      emit(SectionSuccess(sectionModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllSections({String? employeeNumber}) async {
    try {
      emit(SectionLoading());
      final sectionModel = await sectionRepository.getAllSections(
        employeeNumber,
      );
      emit(GetAllSectionSuccess(sectionModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      if (e.response['data'].isNotEmpty &&
          e.response['data']['name']['code'] == 'validation_not_unique') {
        emit(SectionError('The name is already taken.'));
      } else if (e.response['data'].isNotEmpty &&
          e.response['data']['code']['code'] == 'validation_not_unique') {
        emit(SectionError('The code is already taken.'));
      } else {
        emit(SectionError(e.response['message'].toString()));
      }
    } else {
      emit(SectionError(e.toString()));
    }
  }
}
