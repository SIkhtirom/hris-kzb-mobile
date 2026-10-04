import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String role;
  final String activeProjectName;
  final String password;
  final String? profilePicturePath;
  final DateTime? dateOfBirth;

  const User({
    required this.id,
    required this.name,
    required this.role,
    required this.activeProjectName,
    this.password = '',
    this.profilePicturePath,
    this.dateOfBirth,
  });

  User copyWith({
    String? name,
    String? role,
    String? activeProjectName,
    String? password,
    Object? profilePicturePath = _unset,
    Object? dateOfBirth = _unset,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      activeProjectName: activeProjectName ?? this.activeProjectName,
      password: password ?? this.password,
      profilePicturePath: identical(profilePicturePath, _unset)
          ? this.profilePicturePath
          : profilePicturePath as String?,
      dateOfBirth: identical(dateOfBirth, _unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final rawDateOfBirth = json['date_of_birth'];
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      activeProjectName:
          json['active_project_name'] as String? ??
          json['project_name'] as String? ??
          '',
      password: json['password'] as String? ?? '',
      profilePicturePath: json['profile_picture_path'] as String?,
      dateOfBirth: rawDateOfBirth is String
          ? DateTime.tryParse(rawDateOfBirth)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'active_project_name': activeProjectName,
      'password': password,
      'profile_picture_path': profilePicturePath,
      'date_of_birth': dateOfBirth?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    role,
    activeProjectName,
    password,
    profilePicturePath,
    dateOfBirth,
  ];
}

const Object _unset = Object();
