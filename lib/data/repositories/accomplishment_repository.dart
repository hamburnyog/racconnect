import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class AccomplishmentRepository {
  final pb = PocketBaseClient.instance;

  Future<List<AccomplishmentModel>> getAccomplishments() async {
    try {
      final response = await pb.collection('accomplishments').getFullList();
      return response.map((e) => AccomplishmentModel.fromMap(e.toJson())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AccomplishmentModel>> getEmployeeAccomplishments(
      String employeeNumber, DateTime startDate, DateTime endDate) async {
    try {
      final isoStart = startDate.toUtc().toIso8601String().split('.').first;
      final isoEnd = endDate.toUtc().toIso8601String().split('.').first;

      final response = await pb.collection('accomplishments').getFullList(
            filter:
                'date >= "$isoStart" && date <= "$isoEnd" && employeeNumber = "$employeeNumber"',
            sort: '+date',
          );
      return response
          .map((e) => AccomplishmentModel.fromMap(e.toJson()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<AccomplishmentModel?> getAccomplishmentByDate(
      DateTime date, String employeeNumber) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      final isoStart = startOfDay.toUtc().toIso8601String().split('.').first;
      final isoEnd = endOfDay.toUtc().toIso8601String().split('.').first;

      final response = await pb.collection('accomplishments').getFullList(
            filter:
                'date >= "$isoStart" && date <= "$isoEnd" && employeeNumber = "$employeeNumber"',
          );
      if (response.isNotEmpty) {
        return AccomplishmentModel.fromMap(response.first.toJson());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<AccomplishmentModel> addAccomplishment({
    required DateTime date,
    required String target,
    required String accomplishment,
    required String employeeNumber,
  }) async {
    final data = {
      'date': date.toIso8601String(),
      'target': target,
      'accomplishment': accomplishment,
      'employeeNumber': employeeNumber,
    };

    final record = await pb.collection('accomplishments').create(body: data);
    return AccomplishmentModel.fromMap(record.toJson());
  }

  Future<AccomplishmentModel> updateAccomplishment({
    required String id,
    required DateTime date,
    required String target,
    required String accomplishment,
    required String employeeNumber,
  }) async {
    final data = {
      'date': date.toIso8601String(),
      'target': target,
      'accomplishment': accomplishment,
      'employeeNumber': employeeNumber,
    };

    final record = await pb.collection('accomplishments').update(id, body: data);
    return AccomplishmentModel.fromMap(record.toJson());
  }
}
