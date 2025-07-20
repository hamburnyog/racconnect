import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:racconnect/data/models/profile_model.dart';

class UserModel {
  final String? id;
  final String? avatar;
  final String email;
  final String name;
  final bool? verified;
  final String? role;
  final ProfileModel? profile;

  UserModel({
    this.id,
    this.avatar,
    required this.email,
    required this.name,
    this.verified,
    this.role,
    this.profile,
  });

  UserModel copyWith({
    ValueGetter<String?>? id,
    ValueGetter<String?>? avatar,
    String? email,
    String? name,
    ValueGetter<bool?>? verified,
    ValueGetter<String?>? role,
    ValueGetter<ProfileModel?>? profile,
  }) {
    return UserModel(
      id: id != null ? id() : this.id,
      avatar: avatar != null ? avatar() : this.avatar,
      email: email ?? this.email,
      name: name ?? this.name,
      verified: verified != null ? verified() : this.verified,
      role: role != null ? role() : this.role,
      profile: profile != null ? profile() : this.profile,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'avatar': avatar,
      'email': email,
      'name': name,
      'verified': verified,
      'role': role,
      'profile': profile?.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final expand = map['expand'] as Map<String, dynamic>?;

    return UserModel(
      id: map['id'] as String?,
      avatar: map['avatar'] as String?,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      verified: map['verified'] as bool?,
      role: map['role'] as String?,
      profile:
          expand != null && expand['profile'] != null
              ? ProfileModel.fromMap(expand['profile'] as Map<String, dynamic>)
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, avatar: $avatar, email: $email, name: $name, verified: $verified, role: $role, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.avatar == avatar &&
        other.email == email &&
        other.name == name &&
        other.verified == verified &&
        other.role == role &&
        other.profile == profile;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        avatar.hashCode ^
        email.hashCode ^
        name.hashCode ^
        verified.hashCode ^
        role.hashCode ^
        profile.hashCode;
  }
}
