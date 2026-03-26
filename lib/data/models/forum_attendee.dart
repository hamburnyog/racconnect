import 'dart:convert';

class ForumAttendee {
  final String id;
  final String collectionId;
  final String collectionName;
  final String created;
  final String updated;
  final String name;
  final String address;
  final String email;
  final String type;
  final String? spouseName;
  final DateTime? forumDate;
  final DateTime? emailSentDate;

  ForumAttendee({
    this.id = '',
    this.collectionId = '',
    this.collectionName = '',
    this.created = '',
    this.updated = '',
    required this.name,
    required this.address,
    this.email = '',
    this.type = '',
    this.spouseName,
    this.forumDate,
    this.emailSentDate,
  });

  List<String> get emails =>
      email.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  ForumAttendee copyWith({
    String? id,
    String? collectionId,
    String? collectionName,
    String? created,
    String? updated,
    String? name,
    String? address,
    String? email,
    String? type,
    String? spouseName,
    DateTime? forumDate,
    DateTime? emailSentDate,
  }) {
    return ForumAttendee(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      type: type ?? this.type,
      spouseName: spouseName ?? this.spouseName,
      forumDate: forumDate ?? this.forumDate,
      emailSentDate: emailSentDate ?? this.emailSentDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'type': type,
      'spouseName': spouseName,
      'forumDate': forumDate?.toIso8601String(),
      'emailSentDate': emailSentDate?.toIso8601String(),
    };
  }

  factory ForumAttendee.fromMap(Map<String, dynamic> map) {
    return ForumAttendee(
      id: map['id'] ?? '',
      collectionId: map['collectionId'] ?? '',
      collectionName: map['collectionName'] ?? '',
      created: map['created'] ?? '',
      updated: map['updated'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      type: map['type'] ?? '',
      spouseName: map['spouseName'],
      forumDate:
          map['forumDate'] != null && map['forumDate'].toString().isNotEmpty
              ? DateTime.tryParse(map['forumDate'].toString())
              : null,
      emailSentDate: map['emailSentDate'] != null &&
              map['emailSentDate'].toString().isNotEmpty
          ? DateTime.tryParse(map['emailSentDate'].toString())
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ForumAttendee.fromJson(String source) =>
      ForumAttendee.fromMap(json.decode(source));

  factory ForumAttendee.fromRecord(dynamic record) {
    // Handling PocketBase RecordModel to Map conversion if needed,
    // but usually we can just pass record.toJson() or record.data
    // However, the repository usually handles the conversion from RecordModel to our Model.
    // The previous repositories used `AttendanceModel.fromJson(e.toString())` where `e` is likely a RecordModel which has a toString suitable for json decode?
    // Wait, PocketBase `RecordModel` toString() returns the JSON representation? Yes.
    return ForumAttendee.fromJson(record.toString());
  }
}
