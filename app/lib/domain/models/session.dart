import 'app_user.dart';

class Session {
  const Session({
    required this.access,
    required this.refresh,
    required this.user,
  });

  final String access;
  final String refresh;
  final AppUser user;

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      access: json['access'] as String? ?? '',
      refresh: json['refresh'] as String? ?? '',
      user: AppUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'access': access,
    'refresh': refresh,
    'user': user.toJson(),
  };

  Session copyWith({String? access, String? refresh, AppUser? user}) {
    return Session(
      access: access ?? this.access,
      refresh: refresh ?? this.refresh,
      user: user ?? this.user,
    );
  }
}
