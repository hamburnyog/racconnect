import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/repositories/profile_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());
  final ProfileRepository profileRepository = ProfileRepository();

  Future<void> saveProfile({
    String? id,
    required String employeeNumber,
    String? bioId,
    required String firstName,
    String? middleName,
    required String lastName,
    required DateTime birthdate,
    required String gender,
    required String employmentStatus,
    required String position,
    String? sectionId,
  }) async {
    try {
      emit(ProfileLoading());
      final profile = ProfileModel(
        id: id,
        employeeNumber: employeeNumber,
        bioId: bioId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        birthdate: birthdate,
        gender: gender,
        employmentStatus: employmentStatus,
        position: position,
        section: sectionId,
      );
      final updatedProfile = await profileRepository.saveProfile(
        id: id,
        profile: profile,
      );
      emit(SaveProfileSuccess(updatedProfile));
    } catch (e) {
      errorMessage(e);
    }
  }

  Future<void> getAllProfiles() async {
    try {
      emit(ProfileLoading());
      final profiles = await profileRepository.getAllProfiles();
      emit(GetAllProfilesSuccess(profiles));
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
