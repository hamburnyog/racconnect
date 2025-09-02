import 'dart:convert';

import 'package:flutter/widgets.dart';

class LeaveModel {
  final String? id;
  final String employeeNumber;
  final String type;
  final DateTime date;

  LeaveModel({
    this.id,
    required this.employeeNumber,
    required this.type,
    required this.date,
  });

  LeaveModel copyWith({
    ValueGetter<String?>? id,
    String? employeeNumber,
    String? type,
    DateTime? date,
  }) {
    return LeaveModel(
      id: id != null ? id() : this.id,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeNumber': employeeNumber,
      'type': type,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory LeaveModel.fromMap(Map<String, dynamic> map) {
    return LeaveModel(
      id: map['id'],
      employeeNumber: map['employeeNumber'] ?? '',
      type: map['type'] ?? '',
      date: map['date'] != null
          ? (map['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['date'])
              : DateTime.parse(map['date']))
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LeaveModel.fromJson(String source) =>
      LeaveModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LeaveModel(id: $id, employeeNumber: $employeeNumber, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveModel &&
        other.id == id &&
        other.employeeNumber == employeeNumber &&
        other.type == type &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        employeeNumber.hashCode ^
        type.hashCode ^
        date.hashCode;
  }
}