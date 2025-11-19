import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel implements User {
  @Implements<User>()
  const factory UserModel({
    required String id,
    required String email,
    required String nickname,
    String? pictureUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool onboardingCompleted,
  }) = _UserModel;

  const UserModel._();

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

  @override
  bool get stringify => true;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson({
        'id': json['id'],
        'email': json['email'],
        'nickname': json['nickname'],
        'pictureUrl': json['picture_url'],
        'createdAt': json['created_at'],
        'updatedAt': json['updated_at'],
        'onboardingCompleted': json['onboarding_completed'] ?? false,
      });
}
