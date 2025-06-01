import 'dart:convert';

class AttendanceModel {
  final String employeeNumber;
  final DateTime timestamp;
  final String type;
  AttendanceModel({
    required this.employeeNumber,
    required this.timestamp,
    required this.type,
  });

  AttendanceModel copyWith({
    String? employeeNumber,
    DateTime? timestamp,
    String? type,
  }) {
    return AttendanceModel(
      employeeNumber: employeeNumber ?? this.employeeNumber,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeNumber': employeeNumber,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      employeeNumber: map['employeeNumber'] ?? '',
      timestamp:
          map['date'] != null
              ? (map['date'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['date'])
                  : DateTime.parse(map['date']))
              : DateTime.now(),
      type: map['type'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AttendanceModel.fromJson(String source) =>
      AttendanceModel.fromMap(json.decode(source));

  @override
  String toString() =>
      'AttendanceModel(employeeNumber: $employeeNumber, timestamp: $timestamp, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.employeeNumber == employeeNumber &&
        other.timestamp == timestamp &&
        other.type == type;
  }

  @override
  int get hashCode =>
      employeeNumber.hashCode ^ timestamp.hashCode ^ type.hashCode;
}
