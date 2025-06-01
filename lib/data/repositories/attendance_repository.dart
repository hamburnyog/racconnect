import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class AttendanceRepository {
  final pb = PocketBaseClient.instance;

  Future<List<AttendanceModel>> getAllAttendances() async {
    try {
      final response = await pb
          .collection('holidays')
          .getFullList(fields: 'name,date', sort: '+date');
      return response
          .map((e) => AttendanceModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<AttendanceModel> addAttendance({
    required String employeeNumber,
    required DateTime timestamp,
    required String type,
  }) async {
    try {
      final body = <String, dynamic>{
        "employeeNumber": employeeNumber,
        "timestamp": timestamp,
        "type": type,
      };

      final response = await pb.collection('attendance').create(body: body);

      return AttendanceModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }
}
