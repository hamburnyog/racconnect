import 'dart:convert';

class AccomplishmentModel {
  final String? id;
  final DateTime date;
  final String target;
  final String accomplishment;

  AccomplishmentModel({
    this.id,
    required this.date,
    required this.target,
    required this.accomplishment,
  });

  AccomplishmentModel copyWith({
    String? id,
    DateTime? date,
    String? target,
    String? accomplishment,
  }) {
    return AccomplishmentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      target: target ?? this.target,
      accomplishment: accomplishment ?? this.accomplishment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'target': target,
      'accomplishment': accomplishment,
    };
  }

  factory AccomplishmentModel.fromMap(Map<String, dynamic> map) {
    return AccomplishmentModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      target: map['target'] ?? '',
      accomplishment: map['accomplishment'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AccomplishmentModel.fromJson(String source) =>
      AccomplishmentModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AccomplishmentModel(id: $id, date: $date, target: $target, accomplishment: $accomplishment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccomplishmentModel &&
        other.id == id &&
        other.date == date &&
        other.target == target &&
        other.accomplishment == accomplishment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        target.hashCode ^
        accomplishment.hashCode;
  }
}
