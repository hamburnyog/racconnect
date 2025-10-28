import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/utility/app_info.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

class VersionCheckService {
  final PocketBase _pb = PocketBaseClient.instance;

  /// Check if the current app version is outdated compared to the published version in PocketBase
  /// Returns a tuple of (isOutdated, publishedVersion, driveLink) where:
  /// - isOutdated: true if current app version is less than published version
  /// - publishedVersion: the latest version from PocketBase
  /// - driveLink: the Google Drive link for the installer
  Future<({bool isOutdated, String publishedVersion, String? driveLink})>
  checkVersion() async {
    try {
      // Get current app version
      final currentVersion = await AppInfo.getAppVersion();

      // Get the system flags from PocketBase
      final systemFlagsRecords = await _pb
          .collection('systemFlags')
          .getFullList(filter: "key = 'publishedVersion' || key = 'driveLink'");

      String? publishedVersion;
      String? driveLink;

      // Parse the system flags
      for (final record in systemFlagsRecords) {
        final key = record.getStringValue('key');
        final value = record.getStringValue('value');

        if (key == 'publishedVersion') {
          publishedVersion = value;
        } else if (key == 'driveLink') {
          driveLink = value;
        }
      }

      // If we couldn't get the published version, assume current is up to date
      if (publishedVersion == null) {
        return (
          isOutdated: false,
          publishedVersion: currentVersion,
          driveLink: null,
        );
      }

      // Compare versions
      final isOutdated = _isVersionOutdated(currentVersion, publishedVersion);

      return (
        isOutdated: isOutdated,
        publishedVersion: publishedVersion,
        driveLink: driveLink,
      );
    } catch (e) {
      // If there's an error (e.g., network issue, collection doesn't exist),
      // assume the app is up to date to avoid blocking the user
      return (isOutdated: false, publishedVersion: 'unknown', driveLink: null);
    }
  }

  /// Compare two version strings in format "x.y.z"
  /// Returns true if currentVersion is less than publishedVersion
  bool _isVersionOutdated(String currentVersion, String publishedVersion) {
    try {
      final currentParts = currentVersion.split('.');
      final publishedParts = publishedVersion.split('.');

      // Ensure we have at least 3 parts (major.minor.patch)
      while (currentParts.length < 3) {
        currentParts.add('0');
      }
      while (publishedParts.length < 3) {
        publishedParts.add('0');
      }

      for (int i = 0; i < 3; i++) {
        final current = int.tryParse(currentParts[i]) ?? 0;
        final published = int.tryParse(publishedParts[i]) ?? 0;

        if (published > current) {
          return true;
        } else if (published < current) {
          return false;
        }
        // If equal, continue to next part
      }

      // If all parts are equal, the versions are the same, so not outdated
      return false;
    } catch (e) {
      // If parsing fails, assume not outdated to avoid blocking the user
      return false;
    }
  }
}
