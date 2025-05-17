import 'package:racconnect/data/models/section_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class SectionRepository {
  final pb = PocketBaseClient.instance;
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

  Future<SectionModel> updateSection({
    required String id,
    required String name,
    required String code,
  }) async {
    try {
      final body = <String, dynamic>{"name": name, "code": code};

      final response = await pb.collection('sections').update(id, body: body);

      return SectionModel.fromJson(response.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSection({required String id}) async {
    try {
      await pb.collection('sections').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
