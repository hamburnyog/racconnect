import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/utility/app_auth_store.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseClient {
  static final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();
  static const String customUrlKey = 'custom_pocketbase_url';

  static PocketBase? _instance;

  static PocketBase get instance {
    _instance ??= PocketBase(
      Uri.parse(serverUrl).toString(),
      authStore: AppAuthStore(_asyncPrefs),
    );
    return _instance!;
  }

  PocketBaseClient._();

  /// Loads custom PocketBase URL from preferences if configured.
  static Future<void> init() async {
    final customUrl = await _asyncPrefs.getString(customUrlKey);
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      final normalized = _normalizeUrl(customUrl.trim());
      instance.baseURL = normalized;
    }
  }

  /// Returns the configured custom PocketBase URL, or null if using default.
  static Future<String?> getCustomUrl() async {
    return await _asyncPrefs.getString(customUrlKey);
  }

  /// Sets and persists a new PocketBase server URL at runtime.
  static Future<void> updateBaseUrl(String newUrl) async {
    final normalized = _normalizeUrl(newUrl.trim());
    await _asyncPrefs.setString(customUrlKey, normalized);
    instance.baseURL = normalized;
  }

  /// Resets PocketBase URL to the default build-time/environment URL.
  static Future<void> resetToDefault() async {
    await _asyncPrefs.remove(customUrlKey);
    instance.baseURL = Uri.parse(serverUrl).toString();
  }

  /// Tests connectivity to a given PocketBase URL by invoking the health check endpoint.
  static Future<bool> testConnection(String url) async {
    try {
      final normalized = _normalizeUrl(url.trim());
      final testClient = PocketBase(normalized);
      final health = await testClient.health.check().timeout(
        const Duration(seconds: 5),
      );
      return health.code == 200;
    } catch (_) {
      return false;
    }
  }

  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

/// Extracts clean, readable validation and error messages from PocketBase ClientException
String formatPocketBaseError(dynamic error) {
  if (error is ClientException) {
    if (error.statusCode == 404) {
      return 'Collection or record not found (404). Please ensure the collection exists in PocketBase and API rules allow access.';
    }
    final resp = error.response;
    if (resp['data'] is Map && (resp['data'] as Map).isNotEmpty) {
      final fieldErrors = <String>[];
      (resp['data'] as Map).forEach((key, val) {
        if (val is Map && val['message'] != null) {
          fieldErrors.add('$key: ${val['message']}');
        } else if (val is String) {
          fieldErrors.add('$key: $val');
        }
      });
      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join('\n');
      }
    }
    if (resp['message'] != null && resp['message'].toString().isNotEmpty) {
      return resp['message'].toString();
    }
    return error.toString();
  }
  return error.toString();
}
