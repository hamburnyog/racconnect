import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/utility/app_auth_store.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseClient {
  static final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  static final PocketBase _instance = PocketBase(
    Uri.parse(serverUrl).toString(),
    authStore: AppAuthStore(_asyncPrefs),
  );

  PocketBaseClient._();

  static PocketBase get instance => _instance;
}
