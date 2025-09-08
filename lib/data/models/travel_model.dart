import 'dart:convert';

import 'package:flutter/widgets.dart';

class TravelModel {
  final String? id;
  final String soNumber;
  final List<String> employeeNumbers;
  final List<DateTime> specificDates;

  TravelModel({
    this.id,
    required this.soNumber,
    required this.employeeNumbers,
    required this.specificDates,
  });

  TravelModel copyWith({
    ValueGetter<String?>? id,
    String? soNumber,
    List<String>? employeeNumbers,
    List<DateTime>? specificDates,
  }) {
    return TravelModel(
      id: id != null ? id() : this.id,
      soNumber: soNumber ?? this.soNumber,
      employeeNumbers: employeeNumbers ?? this.employeeNumbers,
      specificDates: specificDates ?? this.specificDates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'soNumber': soNumber,
      'employeeNumbers': employeeNumbers,
      'specificDates':
          specificDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  factory TravelModel.fromMap(Map<String, dynamic> map) {
    return TravelModel(
      id: map['id'],
      soNumber: map['soNumber'] ?? '',
      employeeNumbers: List<String>.from(map['employeeNumbers'] ?? []),
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
    );
  }

  String toJson() => json.encode(toMap());

  factory TravelModel.fromJson(String source) =>
      TravelModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'TravelModel(id: $id, soNumber: $soNumber, employeeNumbers: $employeeNumbers, specificDates: $specificDates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TravelModel &&
        other.id == id &&
        other.soNumber == soNumber &&
        other.employeeNumbers == employeeNumbers &&
        other.specificDates == specificDates;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        soNumber.hashCode ^
        employeeNumbers.hashCode ^
        specificDates.hashCode;
  }
}
