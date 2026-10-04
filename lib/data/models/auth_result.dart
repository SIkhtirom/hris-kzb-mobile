import 'package:equatable/equatable.dart';

import 'user.dart';

class AuthResult extends Equatable {
  final String accessToken;
  final String? refreshToken;
  final User user;

  const AuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthResult(
      accessToken:
          json['access_token'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      user: rawUser is Map<String, dynamic>
          ? User.fromJson(rawUser)
          : const User(id: '', name: '', role: '', activeProjectName: ''),
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
