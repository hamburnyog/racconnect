import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class ProfileRepository {
  final pb = PocketBaseClient.instance;

  Future<ProfileModel> saveProfile({
    String? id,
    required String employeeNumber,
    required String firstName,
    required String middleName,
    required String lastName,
    required DateTime birthdate,
    required String gender,
    required String employmentStatus,
    required String position,
    String? sectionId, // <- Add this line
  }) async {
    final data = {
      'employeeNumber': employeeNumber,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'birthdate': birthdate.toIso8601String(),
      'gender': gender,
      'employmentStatus': employmentStatus,
      'position': position,
      if (sectionId != null) 'section': sectionId, // <- Include if set
    };

    final record =
        id != null
            ? await pb.collection('profiles').update(id, body: data)
            : await pb.collection('profiles').create(body: data);

    if (id == null) {
      final profileId = record.id;
      final userId = pb.authStore.record!.id;
      await pb.collection('users').update(userId, body: {'profile': profileId});
    }

    return ProfileModel.fromJson(record.toString());
  }
}
