class AppUser {
  final String userId;
  final String name;
  final String? profileType;

  const AppUser({
    required this.userId,
    required this.name,
    this.profileType,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      profileType: json['profile_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'profile_type': profileType,
    };
  }

  bool get isHans => userId == 'USR-001';
  bool get isBaby => userId == 'USR-002';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

