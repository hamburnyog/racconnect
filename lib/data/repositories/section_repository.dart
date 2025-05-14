import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/section_model.dart';
import 'package:racconnect/utility/constants.dart';

class SectionRepository {
  final pb = PocketBase(Uri.parse(serverUrl).toString());

  Future<List<SectionModel>> getAllSections(employeeNumber) async {
    try {
      final response = await pb
          .collection('sections')
          .getFullList(sort: '+code');

      return response.map((e) => SectionModel.fromJson(e.toString())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<SectionModel> addSection({
    required String name,
    required String code,
  }) async {
    try {
      final body = <String, dynamic>{"name": name, "code": code};

      final response = await pb.collection('sections').create(body: body);

      return SectionModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }
}
