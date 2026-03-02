import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class SignatoryRepository {
  final pb = PocketBaseClient.instance;

  Future<List<SignatoryModel>> getSignatories() async {
    try {
      final response = await pb.collection('signatories').getFullList(
            expand: 'section',
            sort: '+name',
          );

      return response
          .map((e) => SignatoryModel.fromMap(e.toJson()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SignatoryModel>> getSignatoriesBySection(String sectionId) async {
    try {
      final response = await pb.collection('signatories').getFullList(
            filter: 'section = "$sectionId"',
            expand: 'section',
            sort: '+name',
          );

      return response
          .map((e) => SignatoryModel.fromMap(e.toJson()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
