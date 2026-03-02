import 'dart:convert';
import 'package:flutter/widgets.dart';

class SignatoryModel {
  final String? id;
  final String? section;
  final String? sectionName;
  final String? sectionCode;
  final String name;
  final String designation;
  final String? supervisor;
  final String? supervisorDesignation;

  SignatoryModel({
    this.id,
    this.section,
    this.sectionName,
    this.sectionCode,
    required this.name,
    required this.designation,
    this.supervisor,
    this.supervisorDesignation,
  });

  SignatoryModel copyWith({
    ValueGetter<String?>? id,
    ValueGetter<String?>? section,
    ValueGetter<String?>? sectionName,
    ValueGetter<String?>? sectionCode,
    String? name,
    String? designation,
    ValueGetter<String?>? supervisor,
    ValueGetter<String?>? supervisorDesignation,
  }) {
    return SignatoryModel(
      id: id != null ? id() : this.id,
      section: section != null ? section() : this.section,
      sectionName: sectionName != null ? sectionName() : this.sectionName,
      sectionCode: sectionCode != null ? sectionCode() : this.sectionCode,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      supervisor: supervisor != null ? supervisor() : this.supervisor,
      supervisorDesignation: supervisorDesignation != null
          ? supervisorDesignation()
          : this.supervisorDesignation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'section': section,
      'name': name,
      'designation': designation,
      'supervisor': supervisor,
      'supervisorDesignation': supervisorDesignation,
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
      supervisor: map['supervisor'],
      supervisorDesignation: map['supervisorDesignation'],
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
