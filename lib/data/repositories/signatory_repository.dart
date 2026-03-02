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

  Future<SignatoryModel> addSignatory(SignatoryModel signatory) async {
    try {
      final response = await pb.collection('signatories').create(
            body: signatory.toMap(),
            expand: 'section',
          );
      return SignatoryModel.fromMap(response.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<SignatoryModel> updateSignatory(SignatoryModel signatory) async {
    try {
      final response = await pb.collection('signatories').update(
            signatory.id!,
            body: signatory.toMap(),
            expand: 'section',
          );
      return SignatoryModel.fromMap(response.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSignatory(String id) async {
    try {
      await pb.collection('signatories').delete(id);
    } catch (e) {
      rethrow;
    }
  }
}
