import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class SuspensionRepository {
  final pb = PocketBaseClient.instance;
  Future<List<SuspensionModel>> getAllSuspensions() async {
    try {
      final response = await pb
          .collection('suspensions')
          .getFullList(
            sort: '+datetime',
          );
      return response
          .map((e) => SuspensionModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<SuspensionModel> addSuspension({
    required String name,
    required DateTime datetime,
    required bool isHalfday,
  }) async {
    try {
      final body = <String, dynamic>{
        "name": name,
        "datetime": datetime.toIso8601String(),
        "isHalfday": isHalfday,
      };

      final response = await pb.collection('suspensions').create(body: body);

      return SuspensionModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<SuspensionModel> updateSuspension({
    required String id,
    required String name,
    required DateTime datetime,
    required bool isHalfday,
  }) async {
    try {
      final body = <String, dynamic>{
        "name": name,
        "datetime": datetime.toIso8601String(),
        "isHalfday": isHalfday,
      };

      final response = await pb
          .collection('suspensions')
          .update(id, body: body);

      return SuspensionModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSuspension({required String id}) async {
    try {
      await pb.collection('suspensions').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
