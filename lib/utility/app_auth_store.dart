import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAuthStore extends AuthStore {
  final SharedPreferencesAsync asyncPrefs;
  final String key;

  AppAuthStore(this.asyncPrefs, {this.key = "pb_auth"});

  static Future<AppAuthStore> create(
    SharedPreferencesAsync asyncPrefs, {
    String key = "pb_auth",
  }) async {
    final store = AppAuthStore(asyncPrefs, key: key);
    final String? raw = await asyncPrefs.getString(key);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      final token = (decoded as Map<String, dynamic>)["token"] as String? ?? "";
      final model = RecordModel.fromJson(
        decoded["model"] as Map<String, dynamic>? ?? {},
      );

      store.save(token, model);
    }

    return store;
  }

  @override
  void save(String newToken, dynamic newRecord) async {
    super.save(newToken, newRecord);

    final encoded = jsonEncode(<String, dynamic>{
      "token": newToken,
      "model": newRecord,
    });
    asyncPrefs.setString(key, encoded);
  }

  @override
  void clear() async {
    super.clear();
    await asyncPrefs.remove(key);
  }
}
