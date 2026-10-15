import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class ProfileRepository {
  final pb = PocketBaseClient.instance;

  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      final response = await pb
          .collection('profiles')
          .getFullList(sort: '+lastName', expand: 'section,user');
      return response.map((e) => ProfileModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ProfileModel> saveProfile({
    String? id,
    required ProfileModel profile,
  }) async {
    final data = profile.toMap();

    // Remove fields that should not be updated or are expanded
    data.remove('id');
    data.remove('sectionName');
    data.remove('sectionCode');
    data.remove('role');
    data.remove('sl');
    data.remove('vl');
    data.remove('spl');
    data.remove('cto');

    // Convert DateTime to ISO String for PocketBase
    data['birthdate'] = profile.birthdate.toIso8601String();

    late RecordModel record;

    if (id != null) {
      record = await pb.collection('profiles').update(id, body: data);
    } else {
      record = await pb.collection('profiles').create(body: data);
      
      // If we just created a new profile, we must link its ID back to the user record
      final userId = profile.user;
      if (userId != null) {
        await pb.collection('users').update(userId, body: {
          'profile': record.id,
        });
      }
    }

    // Fetch the updated profile with expanded section data
    final updatedRecord = await pb
        .collection('profiles')
        .getOne(record.id, expand: 'section,user');

    return ProfileModel.fromMap(updatedRecord.toJson());
  }
}
