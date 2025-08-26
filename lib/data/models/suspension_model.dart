import 'dart:convert';

import 'package:flutter/widgets.dart';

class SuspensionModel {
  final String? id;
  final String name;
  final DateTime datetime;
  final bool isHalfday;
  SuspensionModel({
    this.id,
    required this.name,
    required this.datetime,
    required this.isHalfday,
  });

  SuspensionModel copyWith({
    ValueGetter<String?>? id,
    String? name,
    DateTime? datetime,
    bool? isHalfday,
  }) {
    return SuspensionModel(
      id: id != null ? id() : this.id,
      name: name ?? this.name,
      datetime: datetime ?? this.datetime,
      isHalfday: isHalfday ?? this.isHalfday,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'datetime': datetime.millisecondsSinceEpoch,
      'isHalfday': isHalfday,
    };
  }

  factory SuspensionModel.fromMap(Map<String, dynamic> map) {
    return SuspensionModel(
      id: map['id'],
      name: map['name'] ?? '',
      datetime:
          map['datetime'] != null
              ? (map['datetime'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['datetime'])
                  : DateTime.parse(map['datetime']))
              : DateTime.now(),
      isHalfday: map['isHalfday'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuspensionModel.fromJson(String source) =>
      SuspensionModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SuspensionModel(id: $id, name: $name, datetime: $datetime, isHalfday: $isHalfday)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SuspensionModel &&
        other.id == id &&
        other.name == name &&
        other.datetime == datetime &&
        other.isHalfday == isHalfday;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ datetime.hashCode ^ isHalfday.hashCode;
  }
}
