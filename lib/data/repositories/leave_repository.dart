import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class LeaveRepository {
  final pb = PocketBaseClient.instance;

  Future<List<LeaveModel>> getAllLeaves() async {
    try {
      final response = await pb.collection('leaves').getFullList();
      return response.map((e) => LeaveModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LeaveModel> addLeave({
    required String type,
    required List<DateTime> specificDates,
    required List<String> employeeNumbers,
  }) async {
    try {
      final body = <String, dynamic>{
        "type": type,
        "specificDates": specificDates.map((e) => e.toIso8601String()).toList(),
        "employeeNumbers": employeeNumbers,
      };

      final response = await pb.collection('leaves').create(body: body);

      return LeaveModel.fromMap(response.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<LeaveModel> updateLeave({
    required String id,
    String? type,
    List<DateTime>? specificDates,
    List<String>? employeeNumbers,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (type != null) body["type"] = type;
      if (specificDates != null) {
        body["specificDates"] =
            specificDates.map((e) => e.toIso8601String()).toList();
      }
      if (employeeNumbers != null) body["employeeNumbers"] = employeeNumbers;

      final response = await pb.collection('leaves').update(id, body: body);

      return LeaveModel.fromMap(response.toJson());
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
