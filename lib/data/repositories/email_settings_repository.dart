import 'package:racconnect/data/models/email_settings_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class EmailSettingsRepository {
  final pb = PocketBaseClient.instance;
  static const String collectionName = 'emailSettings';

  Future<EmailSettingsModel?> getSettings() async {
    try {
      final records = await pb.collection(collectionName).getFullList(
            filter: 'key = "default"',
          );
      if (records.isNotEmpty) {
        return EmailSettingsModel.fromRecord(records.first);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('EmailSettingsRepository error: $e');
      rethrow;
    }
  }

  Future<EmailSettingsModel> saveSettings(EmailSettingsModel settings) async {
    final existing = await getSettings();
    final body = settings.toMap();

    if (existing != null && existing.id != null) {
      final updatedRecord =
          await pb.collection(collectionName).update(existing.id!, body: body);
      return EmailSettingsModel.fromRecord(updatedRecord);
    } else {
      final newRecord = await pb.collection(collectionName).create(body: body);
      return EmailSettingsModel.fromRecord(newRecord);
    }
  }
}
