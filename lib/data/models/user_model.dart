import 'dart:convert';

import 'package:flutter/widgets.dart';

class UserModel {
  final String? id;
  final String email;
  final String name;
  final bool? verified;
  final String? role;
  UserModel({
    this.id,
    required this.email,
    required this.name,
    this.verified,
    this.role,
  });

  UserModel copyWith({
    ValueGetter<String?>? id,
    String? email,
    String? name,
    ValueGetter<bool?>? verified,
    ValueGetter<String?>? role,
  }) {
    return UserModel(
      id: id != null ? id() : this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      verified: verified != null ? verified() : this.verified,
      role: role != null ? role() : this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'verified': verified,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      verified: map['verified'],
      role: map['role'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, verified: $verified, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.verified == verified &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        verified.hashCode ^
        role.hashCode;
  }
}
