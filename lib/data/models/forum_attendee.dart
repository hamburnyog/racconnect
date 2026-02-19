import 'dart:convert';

class ForumAttendee {
  final String id;
  final String collectionId;
  final String collectionName;
  final String created;
  final String updated;
  final String name;
  final String address;
  final DateTime? forumDate;
  final DateTime? certificateDate;

  ForumAttendee({
    this.id = '',
    this.collectionId = '',
    this.collectionName = '',
    this.created = '',
    this.updated = '',
    required this.name,
    required this.address,
    this.forumDate,
    this.certificateDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      if (forumDate != null) 'forumDate': forumDate!.toIso8601String(),
      if (certificateDate != null)
        'certificateDate': certificateDate!.toIso8601String(),
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
      forumDate:
          map['forumDate'] != null && map['forumDate'].toString().isNotEmpty
              ? DateTime.tryParse(map['forumDate'].toString())
              : null,
      certificateDate:
          map['certificateDate'] != null &&
                  map['certificateDate'].toString().isNotEmpty
              ? DateTime.tryParse(map['certificateDate'].toString())
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
