import 'package:pocketbase/pocketbase.dart';

class EmailSettingsModel {
  final String? id;
  final String key;
  final String smtpUsername;
  final String smtpPassword;
  final String smtpServer;
  final int smtpPort;
  final String smtpFromEmail;
  final String smtpFromName;
  final String preAdoptionTemplate;
  final String fosterCareTemplate;

  EmailSettingsModel({
    this.id,
    this.key = 'default',
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.smtpServer = 'smtp.gmail.com',
    this.smtpPort = 587,
    this.smtpFromEmail = '',
    this.smtpFromName = 'RACCONNECT Forum',
    this.preAdoptionTemplate = '',
    this.fosterCareTemplate = '',
  });

  EmailSettingsModel copyWith({
    String? id,
    String? key,
    String? smtpUsername,
    String? smtpPassword,
    String? smtpServer,
    int? smtpPort,
    String? smtpFromEmail,
    String? smtpFromName,
    String? preAdoptionTemplate,
    String? fosterCareTemplate,
  }) {
    return EmailSettingsModel(
      id: id ?? this.id,
      key: key ?? this.key,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpServer: smtpServer ?? this.smtpServer,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpFromEmail: smtpFromEmail ?? this.smtpFromEmail,
      smtpFromName: smtpFromName ?? this.smtpFromName,
      preAdoptionTemplate: preAdoptionTemplate ?? this.preAdoptionTemplate,
      fosterCareTemplate: fosterCareTemplate ?? this.fosterCareTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'smtpUsername': smtpUsername,
      'smtpPassword': smtpPassword,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'smtpFromEmail': smtpFromEmail,
      'smtpFromName': smtpFromName,
      'preAdoptionTemplate': preAdoptionTemplate,
      'fosterCareTemplate': fosterCareTemplate,
    };
  }

  factory EmailSettingsModel.fromRecord(RecordModel record) {
    return EmailSettingsModel(
      id: record.id,
      key: record.getStringValue('key', 'default'),
      smtpUsername: record.getStringValue('smtpUsername'),
      smtpPassword: record.getStringValue('smtpPassword'),
      smtpServer: record.getStringValue('smtpServer', 'smtp.gmail.com'),
      smtpPort: record.getIntValue('smtpPort', 587),
      smtpFromEmail: record.getStringValue('smtpFromEmail'),
      smtpFromName: record.getStringValue('smtpFromName', 'RACCONNECT Forum'),
      preAdoptionTemplate: record.getStringValue('preAdoptionTemplate'),
      fosterCareTemplate: record.getStringValue('fosterCareTemplate'),
    );
  }

  factory EmailSettingsModel.fromMap(Map<String, dynamic> map) {
    return EmailSettingsModel(
      id: map['id'] as String?,
      key: map['key'] as String? ?? 'default',
      smtpUsername: map['smtpUsername'] as String? ?? '',
      smtpPassword: map['smtpPassword'] as String? ?? '',
      smtpServer: map['smtpServer'] as String? ?? 'smtp.gmail.com',
      smtpPort: (map['smtpPort'] as num?)?.toInt() ?? 587,
      smtpFromEmail: map['smtpFromEmail'] as String? ?? '',
      smtpFromName: map['smtpFromName'] as String? ?? 'RACCONNECT Forum',
      preAdoptionTemplate: map['preAdoptionTemplate'] as String? ?? '',
      fosterCareTemplate: map['fosterCareTemplate'] as String? ?? '',
    );
  }
}
