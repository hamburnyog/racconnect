import 'dart:convert';

import 'package:flutter/foundation.dart';

class LeaveModel {
  final String? id;
  final String type;
  final List<DateTime> specificDates;
  final List<String> employeeNumbers;

  LeaveModel({
    this.id,
    required this.type,
    required this.specificDates,
    required this.employeeNumbers,
  });

  LeaveModel copyWith({
    String? id,
    String? type,
    List<DateTime>? specificDates,
    List<String>? employeeNumbers,
  }) {
    return LeaveModel(
      id: id ?? this.id,
      type: type ?? this.type,
      specificDates: specificDates ?? this.specificDates,
      employeeNumbers: employeeNumbers ?? this.employeeNumbers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'specificDates': specificDates.map((x) => x.toIso8601String()).toList(),
      'employeeNumbers': employeeNumbers,
    };
  }

  factory LeaveModel.fromMap(Map<String, dynamic> map) {
    return LeaveModel(
      id: map['id'],
      type: map['type'] ?? '',
      specificDates: List<DateTime>.from(
        (map['specificDates'] ?? []).map((date) {
          if (date is int) {
            return DateTime.fromMillisecondsSinceEpoch(date);
          } else if (date is String) {
            return DateTime.parse(date);
          } else {
            return DateTime.now();
          }
        }),
      ),
      employeeNumbers: List<String>.from(map['employeeNumbers'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory LeaveModel.fromJson(String source) =>
      LeaveModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LeaveModel(id: $id, type: $type, specificDates: $specificDates, employeeNumbers: $employeeNumbers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveModel &&
        other.id == id &&
        other.type == type &&
        listEquals(other.specificDates, specificDates) &&
        listEquals(other.employeeNumbers, employeeNumbers);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        specificDates.hashCode ^
        employeeNumbers.hashCode;
  }
}
