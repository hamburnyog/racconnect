import 'dart:convert';

class AccomplishmentModel {
  final String? id;
  final DateTime date;
  final String targets;
  final String accomplishments;

  AccomplishmentModel({
    this.id,
    required this.date,
    required this.targets,
    required this.accomplishments,
  });

  AccomplishmentModel copyWith({
    String? id,
    DateTime? date,
    String? targets,
    String? accomplishments,
  }) {
    return AccomplishmentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      targets: targets ?? this.targets,
      accomplishments: accomplishments ?? this.accomplishments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'targets': targets,
      'accomplishments': accomplishments,
    };
  }

  factory AccomplishmentModel.fromMap(Map<String, dynamic> map) {
    return AccomplishmentModel(
      id: map['id'],
      date: DateTime.parse(map['date']),
      targets: map['targets'] ?? '',
      accomplishments: map['accomplishments'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory AccomplishmentModel.fromJson(String source) =>
      AccomplishmentModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AccomplishmentModel(id: $id, date: $date, targets: $targets, accomplishments: $accomplishments)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccomplishmentModel &&
        other.id == id &&
        other.date == date &&
        other.targets == targets &&
        other.accomplishments == accomplishments;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        targets.hashCode ^
        accomplishments.hashCode;
  }
}
