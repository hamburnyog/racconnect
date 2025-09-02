import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';
import 'package:http/http.dart' as http;

class AttendanceRepository {
  final pb = PocketBaseClient.instance;

  Future<List<AttendanceModel>> getAllAttendances() async {
    try {
      final response = await pb
          .collection('attendance')
          .getFullList(sort: '+date');
      return response
          .map((e) => AttendanceModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getAllAttendanceToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final isoStart = startOfDay.toUtc().toIso8601String().split('.').first;
      final isoEnd = endOfDay.toUtc().toIso8601String().split('.').first;

      final response = await pb
          .collection('attendance')
          .getFullList(
            filter: 'timestamp >= "$isoStart" && timestamp <= "$isoEnd"',
            sort: '+timestamp',
          );
      return response
          .map((e) => AttendanceModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getEmployeeAttendance(employeeNumber) async {
    try {
      final response = await pb
          .collection('attendance')
          .getFullList(
            filter: 'employeeNumber = "$employeeNumber"',
            sort: '+timestamp',
          );

      return response
          .map((e) => AttendanceModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getEmployeeAttendanceToday(
    employeeNumber,
  ) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      final isoStart = startOfDay.toUtc().toIso8601String().split('.').first;
      final isoEnd = endOfDay.toUtc().toIso8601String().split('.').first;

      final response = await pb
          .collection('attendance')
          .getFullList(
            filter:
                'employeeNumber = "$employeeNumber" && timestamp >= "$isoStart" && timestamp <= "$isoEnd"',
            sort: '+timestamp',
          );
      return response
          .map((e) => AttendanceModel.fromJson(e.toString()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getEmployeeAttendanceForMonth(
    String? employeeNumber,
    DateTime selectedDate,
  ) async {
    try {
      // Get start and end of the month
      final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      final endOfMonth = DateTime(
        selectedDate.year,
        selectedDate.month + 1,
        1,
      ).subtract(const Duration(milliseconds: 1));

      final isoStart = startOfMonth.toUtc().toIso8601String().split('.').first;
      final isoEnd = endOfMonth.toUtc().toIso8601String().split('.').first;

      final response = await pb
          .collection('attendance')
          .getFullList(
            filter:
                'employeeNumber = "$employeeNumber" && timestamp >= "$isoStart" && timestamp <= "$isoEnd"',
            sort: '+timestamp',
          );

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
    required String remarks,
    String? accomplishmentId,
  }) async {
    try {
      final ipAddress = await getIpAddress();

      final body = <String, dynamic>{
        "employeeNumber": employeeNumber,
        "timestamp": timestamp.toIso8601String(),
        "type": 'WFH',
        "remarks": remarks,
        "ipAddress": ipAddress,
        if (accomplishmentId != null) "accomplishmentId": accomplishmentId,
      };

      final response = await pb.collection('attendance').create(body: body);

      return AttendanceModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<AttendanceModel?> uploadAttendance({
    required String employeeNumber,
    required DateTime timestamp,
  }) async {
    try {
      final body = <String, dynamic>{
        "employeeNumber": employeeNumber,
        "timestamp": timestamp.toIso8601String(),
        "type": 'Biometrics',
        "remarks": "Extracted from biometric device.",
      };

      final response = await pb.collection('attendance').create(body: body);
      return AttendanceModel.fromJson(response.toString());
    } on ClientException catch (e) {
      if (e.statusCode == 400 &&
          e.response.toString().contains('employeeNumber') &&
          e.response.toString().contains('timestamp')) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getIpAddress() async {
    try {
      final url = Uri.parse('https://api.ipify.org');
      final response = await http.get(url);

      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      rethrow;
    }
  }
}
