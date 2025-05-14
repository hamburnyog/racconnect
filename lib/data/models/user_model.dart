import 'dart:convert';

import 'package:flutter/widgets.dart';

class UserModel {
  final String? id;
  final String email;
  final bool? verified;
  final String? employeeNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime? birthdate;
  final String? role;
  UserModel({
    this.id,
    required this.email,
    this.verified,
    this.employeeNumber,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.birthdate,
    this.role,
  });

  UserModel copyWith({
    ValueGetter<String?>? id,
    String? email,
    ValueGetter<bool?>? verified,
    ValueGetter<String?>? employeeNumber,
    String? firstName,
    ValueGetter<String?>? middleName,
    String? lastName,
    ValueGetter<DateTime?>? birthdate,
    ValueGetter<String?>? role,
  }) {
    return UserModel(
      id: id != null ? id() : this.id,
      email: email ?? this.email,
      verified: verified != null ? verified() : this.verified,
      employeeNumber:
          employeeNumber != null ? employeeNumber() : this.employeeNumber,
      firstName: firstName ?? this.firstName,
      middleName: middleName != null ? middleName() : this.middleName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate != null ? birthdate() : this.birthdate,
      role: role != null ? role() : this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'verified': verified,
      'employeeNumber': employeeNumber,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'birthdate': birthdate?.millisecondsSinceEpoch,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'] ?? '',
      verified: map['verified'] ?? '',
      employeeNumber: map['employeeNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthdate:
          map['birthdate'] != null
              ? (map['birthdate'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['birthdate'])
                  : DateTime.tryParse(map['birthdate']))
              : null,
      role: map['role'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, verified: $verified, employeeNumber: $employeeNumber, firstName: $firstName, middleName: $middleName, lastName: $lastName, birthdate: $birthdate, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.verified == verified &&
        other.employeeNumber == employeeNumber &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        other.birthdate == birthdate &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        verified.hashCode ^
        employeeNumber.hashCode ^
        firstName.hashCode ^
        middleName.hashCode ^
        lastName.hashCode ^
        birthdate.hashCode ^
        role.hashCode;
  }
}
