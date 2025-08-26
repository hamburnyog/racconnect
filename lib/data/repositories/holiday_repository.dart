import 'package:racconnect/data/models/holiday_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class HolidayRepository {
  final pb = PocketBaseClient.instance;
  Future<List<HolidayModel>> getAllHolidays(employeeNumber) async {
    try {
      final response = await pb
          .collection('holidays')
          .getFullList(
            sort: '+date',
            // filter:
            //     'date >= "${DateTime.now().year}-01-01" && date <= "${DateTime.now().year}-12-31"',
          );
      return response.map((e) => HolidayModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<HolidayModel> addHoliday({
    required String name,
    required DateTime date,
  }) async {
    try {
      final body = <String, dynamic>{
        "name": name,
        "date": date.toIso8601String(),
      };

      final response = await pb.collection('holidays').create(body: body);

      return HolidayModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<HolidayModel> updateHoliday({
    required String id,
    required String name,
    required DateTime date,
  }) async {
    try {
      final body = <String, dynamic>{
        "name": name,
        "date": date.toIso8601String(),
      };

      final response = await pb.collection('holidays').update(id, body: body);

      return HolidayModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHoliday({required String id}) async {
    try {
      await pb.collection('holidays').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
