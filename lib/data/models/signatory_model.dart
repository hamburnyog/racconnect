import 'dart:convert';
import 'package:flutter/widgets.dart';

class SignatoryModel {
  final String? id;
  final String? section;
  final String? sectionName;
  final String? sectionCode;
  final String name;
  final String designation;

  SignatoryModel({
    this.id,
    this.section,
    this.sectionName,
    this.sectionCode,
    required this.name,
    required this.designation,
  });

  SignatoryModel copyWith({
    ValueGetter<String?>? id,
    ValueGetter<String?>? section,
    ValueGetter<String?>? sectionName,
    ValueGetter<String?>? sectionCode,
    String? name,
    String? designation,
  }) {
    return SignatoryModel(
      id: id != null ? id() : this.id,
      section: section != null ? section() : this.section,
      sectionName: sectionName != null ? sectionName() : this.sectionName,
      sectionCode: sectionCode != null ? sectionCode() : this.sectionCode,
      name: name ?? this.name,
      designation: designation ?? this.designation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section': section,
      'sectionName': sectionName,
      'sectionCode': sectionCode,
      'name': name,
      'designation': designation,
    };
  }

  factory SignatoryModel.fromMap(Map<String, dynamic> map) {
    // Handle expansion if available
    final expandedSection = map['expand']?['section'];
    
    return SignatoryModel(
      id: map['id'],
      section: map['section'],
      sectionName: expandedSection?['name'] ?? map['sectionName'],
      sectionCode: expandedSection?['code'] ?? map['sectionCode'],
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SignatoryModel.fromJson(String source) =>
      SignatoryModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SignatoryModel(id: $id, section: $section, sectionName: $sectionName, sectionCode: $sectionCode, name: $name, designation: $designation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SignatoryModel &&
        other.id == id &&
        other.section == section &&
        other.sectionName == sectionName &&
        other.sectionCode == sectionCode &&
        other.name == name &&
        other.designation == designation;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        section.hashCode ^
        sectionName.hashCode ^
        sectionCode.hashCode ^
        name.hashCode ^
        designation.hashCode;
  }
}
