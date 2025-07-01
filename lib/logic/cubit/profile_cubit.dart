import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/repositories/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());
  final ProfileRepository profileRepository = ProfileRepository();

  Future<void> saveProfile({
    String? id,
    required String employeeNumber,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime birthdate,
    required String gender,
    required String employmentStatus,
    required String position,
    required String sectionId,
  }) async {
    try {
      emit(ProfileLoading());
      await profileRepository.saveProfile(
        id: id,
        employeeNumber: employeeNumber,
        firstName: firstName,
        middleName: middleName ?? '',
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        employmentStatus: employmentStatus,
        position: position,
        sectionId: sectionId,
      );
      emit(SaveProfileSuccess());
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
          data['employeeNumber'] != null &&
          data['employeeNumber']['code'] == 'validation_not_unique') {
        emit(ProfileError('The employee number is already taken.'));
      } else {
        emit(ProfileError(message?.toString() ?? 'Unknown error'));
      }
    } else {
      emit(ProfileError(e.toString()));
    }
  }
}
