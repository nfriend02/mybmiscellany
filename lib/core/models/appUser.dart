class AppUser {
  const AppUser({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.createdAt,
    this.phone = '',
    this.loginKind = '',
    this.signedIn = false,
    this.admin = false,
  });

  factory AppUser.guest() {
    return AppUser(
      userId: '',
      displayName: '게스트',
      email: '',
      avatarUrl: '',
      createdAt: DateTime.now(),
    );
  }

  final String userId;
  final String displayName;
  final String email;
  final String avatarUrl;
  final DateTime createdAt;
  final String phone;
  final String loginKind;
  final bool signedIn;
  final bool admin;

  String get loginLabel {
    if (email.isNotEmpty) return email;
    if (phone.isNotEmpty) return phone;
    return '';
  }

  AppUser copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    String? phone,
    String? loginKind,
    bool? signedIn,
    bool? admin,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      loginKind: loginKind ?? this.loginKind,
      signedIn: signedIn ?? this.signedIn,
      admin: admin ?? this.admin,
    );
  }
}
