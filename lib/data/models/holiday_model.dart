import 'dart:convert';

import 'package:flutter/widgets.dart';

class HolidayModel {
  final String? id;
  final String name;
  final DateTime date;
  HolidayModel({this.id, required this.name, required this.date});

  HolidayModel copyWith({
    ValueGetter<String?>? id,
    String? name,
    DateTime? date,
  }) {
    return HolidayModel(
      id: id != null ? id() : this.id,
      name: name ?? this.name,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'date': date.millisecondsSinceEpoch};
  }

  factory HolidayModel.fromMap(Map<String, dynamic> map) {
    return HolidayModel(
      id: map['id'],
      name: map['name'] ?? '',
      date:
          map['date'] != null
              ? (map['date'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['date'])
                  : DateTime.parse(map['date']))
              : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory HolidayModel.fromJson(String source) =>
      HolidayModel.fromMap(json.decode(source));

  @override
  String toString() => 'HolidayModel(id: $id, name: $name, date: $date)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HolidayModel &&
        other.id == id &&
        other.name == name &&
        other.date == date;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ date.hashCode;
}
