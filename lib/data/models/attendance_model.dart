import 'dart:convert';

class AttendanceModel {
  final String employeeNumber;
  final DateTime timestamp;
  final String type;
  final String remarks;
  AttendanceModel({
    required this.employeeNumber,
    required this.timestamp,
    required this.type,
    required this.remarks,
  });

  AttendanceModel copyWith({
    String? employeeNumber,
    DateTime? timestamp,
    String? type,
    String? remarks,
  }) {
    return AttendanceModel(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeNumber': employeeNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'remarks': remarks,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      employeeNumber: map['employeeNumber'] ?? '',
      timestamp:
          (map['date'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['date'])
              : DateTime.parse(map['date'])),
      type: map['type'] ?? '',
      remarks: map['remarks'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AttendanceModel(employeeNumber: $employeeNumber, timestamp: $timestamp, type: $type, remarks: $remarks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.employeeNumber == employeeNumber &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.remarks == remarks;
  }

  @override
  int get hashCode {
    return employeeNumber.hashCode ^
        timestamp.hashCode ^
        type.hashCode ^
        remarks.hashCode;
  }
}
