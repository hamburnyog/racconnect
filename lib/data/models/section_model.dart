import 'dart:convert';

import 'package:flutter/widgets.dart';

class SectionModel {
  final String? id;
  final String name;
  final String code;

  SectionModel({this.id, required this.name, required this.code});

  SectionModel copyWith({
    ValueGetter<String?>? id,
    String? name,
    String? code,
  }) {
    return SectionModel(
      id: id != null ? id() : this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'code': code};
  }

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id: map['id'],
      name: map['name'] ?? '',
      code: map['code'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SectionModel.fromJson(String source) =>
      SectionModel.fromMap(json.decode(source));

  @override
  String toString() => 'SectionModel(id: $id, name: $name, code: $code)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SectionModel &&
        other.id == id &&
        other.name == name &&
        other.code == code;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ code.hashCode;
}
