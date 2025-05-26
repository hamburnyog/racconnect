import 'dart:convert';

class EventModel {
  final String name;
  final DateTime date;
  EventModel({required this.name, required this.date});

  EventModel copyWith({String? name, DateTime? date}) {
    return EventModel(name: name ?? this.name, date: date ?? this.date);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'date': date.millisecondsSinceEpoch};
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      name: map['name'] ?? '',
      date:
          map['date'] != null
              ? (map['date'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['date'])
                  : DateTime.parse(map['date']))
              : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source) =>
      EventModel.fromMap(json.decode(source));

  @override
  String toString() => 'EventModel(name: $name, date: $date)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventModel && other.name == name && other.date == date;
  }

  @override
  int get hashCode => name.hashCode ^ date.hashCode;
}
