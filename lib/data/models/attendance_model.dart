import 'dart:convert';

import 'package:flutter/widgets.dart';

class AttendanceModel {
  final String? id;
  final String employeeNumber;
  final DateTime timestamp;
  final String type;
  final String remarks;
  final String? ipAddress;
  final String? accomplishmentId;
  AttendanceModel({
    this.id,
    required this.employeeNumber,
    required this.timestamp,
    required this.type,
    required this.remarks,
    this.ipAddress,
    this.accomplishmentId,
  });

  AttendanceModel copyWith({
    String? id,
    String? employeeNumber,
    DateTime? timestamp,
    String? type,
    String? remarks,
    ValueGetter<String?>? ipAddress,
    ValueGetter<String?>? accomplishmentId,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      remarks: remarks ?? this.remarks,
      ipAddress: ipAddress != null ? ipAddress() : this.ipAddress,
      accomplishmentId:
          accomplishmentId != null ? accomplishmentId() : this.accomplishmentId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeNumber': employeeNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'remarks': remarks,
      'ipAddress': ipAddress,
      'accomplishmentId': accomplishmentId,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      employeeNumber: map['employeeNumber'] ?? '',
      timestamp:
          (map['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.parse(map['timestamp'])),
      type: map['type'] ?? '',
      remarks: map['remarks'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      accomplishmentId: map['accomplishmentId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AttendanceModel(id: $id, employeeNumber: $employeeNumber, timestamp: $timestamp, type: $type, remarks: $remarks, ipAddress: $ipAddress, accomplishmentId: $accomplishmentId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.id == id &&
        other.employeeNumber == employeeNumber &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.remarks == remarks &&
        other.ipAddress == ipAddress &&
        other.accomplishmentId == accomplishmentId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        employeeNumber.hashCode ^
        timestamp.hashCode ^
        type.hashCode ^
        remarks.hashCode ^
        ipAddress.hashCode ^
        accomplishmentId.hashCode;
  }
}
