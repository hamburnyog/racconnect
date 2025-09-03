import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class LeaveRepository {
  final pb = PocketBaseClient.instance;

  Future<List<LeaveModel>> getAllLeaves(String employeeNumber) async {
    try {
      final response = await pb
          .collection('leaves')
          .getFullList(
            sort: '-date',
            filter: 'employeeNumber = "$employeeNumber"',
          );
      return response.map((e) => LeaveModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LeaveModel> addLeave({
    required String employeeNumber,
    required String type,
    required DateTime date,
  }) async {
    try {
      final body = <String, dynamic>{
        "employeeNumber": employeeNumber,
        "type": type,
        "date": date.toIso8601String(),
      };

      final response = await pb.collection('leaves').create(body: body);

      return LeaveModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<LeaveModel> updateLeave({
    required String id,
    String? type,
    DateTime? date,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (type != null) body["type"] = type;
      if (date != null) body["date"] = date.toIso8601String();

      final response = await pb.collection('leaves').update(id, body: body);

      return LeaveModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLeave({required String id}) async {
    try {
      await pb.collection('leaves').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
