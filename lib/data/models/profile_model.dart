import 'dart:convert';

import 'package:flutter/widgets.dart';

class ProfileModel {
  final String? id;
  final String? employeeNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime birthdate;
  final String gender;
  final String position;
  final String employmentStatus;
  final String? section;
  final String? sectionName;
  ProfileModel({
    this.id,
    this.employeeNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthdate,
    required this.gender,
    required this.position,
    required this.employmentStatus,
    this.section,
    this.sectionName,
  });

  ProfileModel copyWith({
    ValueGetter<String?>? id,
    ValueGetter<String?>? employeeNumber,
    String? firstName,
    ValueGetter<String?>? middleName,
    String? lastName,
    DateTime? birthdate,
    String? gender,
    String? position,
    String? employmentStatus,
    String? section,
    String? sectionName,
  }) {
    return ProfileModel(
      id: id != null ? id() : this.id,
      employeeNumber:
          employeeNumber != null ? employeeNumber() : this.employeeNumber,
      firstName: firstName ?? this.firstName,
      middleName: middleName != null ? middleName() : this.middleName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      position: position ?? this.position,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      section: section ?? this.section,
      sectionName: sectionName ?? this.sectionName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeNumber': employeeNumber,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'birthdate': birthdate.millisecondsSinceEpoch,
      'gender': gender,
      'employmentStatus': employmentStatus,
      'section': section,
      'sectionName': sectionName,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      employeeNumber: map['employeeNumber'],
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'],
      lastName: map['lastName'] ?? '',
      birthdate:
          (map['birthdate'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['birthdate'])
              : DateTime.parse(map['birthdate'])),
      gender: map['gender'] ?? '',
      position: map['position'] ?? '',
      employmentStatus: map['employmentStatus'] ?? '',
      section: map['section'] ?? '',
      sectionName: map['sectionName'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfileModel.fromJson(String source) =>
      ProfileModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ProfileModel(id: $id, employeeNumber: $employeeNumber, firstName: $firstName, middleName: $middleName, lastName: $lastName, birthdate: $birthdate, gender: $gender, position: $position, employmentStatus: $employmentStatus, section: $section, sectionName: $sectionName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel &&
        other.id == id &&
        other.employeeNumber == employeeNumber &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        other.birthdate == birthdate &&
        other.gender == gender &&
        other.position == position &&
        other.employmentStatus == employmentStatus &&
        other.section == section &&
        other.sectionName == sectionName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        employeeNumber.hashCode ^
        firstName.hashCode ^
        middleName.hashCode ^
        lastName.hashCode ^
        birthdate.hashCode ^
        gender.hashCode ^
        position.hashCode ^
        section.hashCode ^
        sectionName.hashCode ^
        employmentStatus.hashCode;
  }
}
