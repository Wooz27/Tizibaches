class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? avatarUrl;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email.split('@').first : full;
  }

  String get initials {
    final source = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return source.isEmpty ? 'B' : source;
  }

  bool get isStaff => role == 'staff';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: json['role'] as String? ?? 'citizen',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'role': role,
    'avatar_url': avatarUrl,
  };
}
