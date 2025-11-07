import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String nickname;
  final String? pictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool onboardingCompleted;

  const User({
    required this.id,
    required this.email,
    required this.nickname,
    this.pictureUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.onboardingCompleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      pictureUrl: json['picture_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      onboardingCompleted: json['onboarding_completed'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        nickname,
        pictureUrl,
        createdAt,
        updatedAt,
        onboardingCompleted
      ];
}
