import 'dart:convert';

import 'package:flutter/widgets.dart';

class AttendanceModel {
  final String employeeNumber;
  final DateTime timestamp;
  final String type;
  final String remarks;
  final String? ipAddress;
  AttendanceModel({
    required this.employeeNumber,
    required this.timestamp,
    required this.type,
    required this.remarks,
    this.ipAddress,
  });

  AttendanceModel copyWith({
    String? employeeNumber,
    DateTime? timestamp,
    String? type,
    String? remarks,
    ValueGetter<String?>? ipAddress,
  }) {
    return AttendanceModel(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      remarks: remarks ?? this.remarks,
      ipAddress: ipAddress != null ? ipAddress() : this.ipAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeNumber': employeeNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'remarks': remarks,
      'ipAddress': ipAddress,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      employeeNumber: map['employeeNumber'] ?? '',
      timestamp:
          (map['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.parse(map['timestamp'])),
      type: map['type'] ?? '',
      remarks: map['remarks'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AttendanceModel(employeeNumber: $employeeNumber, timestamp: $timestamp, type: $type, remarks: $remarks, ipAddress: $ipAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.employeeNumber == employeeNumber &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.remarks == remarks &&
        other.ipAddress == ipAddress;
  }

  @override
  int get hashCode {
    return employeeNumber.hashCode ^
        timestamp.hashCode ^
        type.hashCode ^
        remarks.hashCode ^
        ipAddress.hashCode;
  }
}
