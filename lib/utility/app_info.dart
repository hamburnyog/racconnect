import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class AppInfo {
  static Future<String> getAppVersion() async {
    try {
      // Load the pubspec.yaml file
      final pubspec = await rootBundle.loadString('pubspec.yaml');
      final yaml = loadYaml(pubspec);

      // Extract the version
      final version = yaml['version'] as String;

      // Remove the build number (after the + sign) if present
      final versionParts = version.split('+');
      return versionParts[0];
    } catch (e) {
      // Return a default version if there's an error
      return '1.0.0';
    }
  }
}
