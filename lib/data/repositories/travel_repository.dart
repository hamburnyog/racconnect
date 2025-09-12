import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class TravelRepository {
  final pb = PocketBaseClient.instance;

  Future<List<TravelModel>> getAllTravels() async {
    try {
      final response = await pb
          .collection('travels')
          .getFullList(sort: 'soNumber');
      return response.map((e) => TravelModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TravelModel>> getEmployeeTravels(String employeeNumber) async {
    try {
      final response = await pb
          .collection('travels')
          .getFullList(filter: 'employeeNumbers ~ "$employeeNumber"');
      return response.map((e) => TravelModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TravelModel> addTravel({
    required String soNumber,
    required List<String> employeeNumbers,
    required List<DateTime> specificDates,
  }) async {
    try {
      final body = <String, dynamic>{
        "soNumber": soNumber,
        "employeeNumbers": employeeNumbers,
        "specificDates":
            specificDates.map((date) => date.toIso8601String()).toList(),
      };

      final response = await pb.collection('travels').create(body: body);

      return TravelModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<TravelModel> updateTravel({
    required String id,
    required String soNumber,
    required List<String> employeeNumbers,
    required List<DateTime> specificDates,
  }) async {
    try {
      final body = <String, dynamic>{
        "soNumber": soNumber,
        "employeeNumbers": employeeNumbers,
        "specificDates":
            specificDates.map((date) => date.toIso8601String()).toList(),
      };

      final response = await pb.collection('travels').update(id, body: body);

      return TravelModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTravel({required String id}) async {
    try {
      await pb.collection('travels').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
