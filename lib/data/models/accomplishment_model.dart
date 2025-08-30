import 'dart:convert';

class AccomplishmentModel {
  final String? id;
  final DateTime date;
  final String target;
  final String accomplishment;
  final String employeeNumber;

  AccomplishmentModel({
    this.id,
    required this.date,
    required this.target,
    required this.accomplishment,
    required this.employeeNumber,
  });

  AccomplishmentModel copyWith({
    String? id,
    DateTime? date,
    String? target,
    String? accomplishment,
    String? employeeNumber,
  }) {
    return AccomplishmentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      target: target ?? this.target,
      accomplishment: accomplishment ?? this.accomplishment,
      employeeNumber: employeeNumber ?? this.employeeNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'target': target,
      'accomplishment': accomplishment,
      'employeeNumber': employeeNumber,
    };
  }

  factory AccomplishmentModel.fromMap(Map<String, dynamic> map) {
    return AccomplishmentModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      target: map['target'] ?? '',
      accomplishment: map['accomplishment'] ?? '',
      employeeNumber: map['employeeNumber'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AccomplishmentModel.fromJson(String source) =>
      AccomplishmentModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AccomplishmentModel(id: $id, date: $date, target: $target, accomplishment: $accomplishment, employeeNumber: $employeeNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccomplishmentModel &&
        other.id == id &&
        other.date == date &&
        other.target == target &&
        other.accomplishment == accomplishment &&
        other.employeeNumber == employeeNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        target.hashCode ^
        accomplishment.hashCode ^
        employeeNumber.hashCode;
  }
}
