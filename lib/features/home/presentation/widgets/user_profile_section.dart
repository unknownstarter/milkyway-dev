import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserProfileSection extends ConsumerWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFECECEC)),
      );
    }

    if (authState.hasError) {
      return Center(
        child: Text(
          '사용자 정보를 불러올 수 없습니다.',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    final user = authState.value;

    if (user == null) {
      return Center(
        child: Text(
          '사용자 정보가 없습니다.',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.pictureUrl != null && user.pictureUrl!.isNotEmpty
                    ? NetworkImage(user.pictureUrl!)
                    : null,
            child: user.pictureUrl == null || user.pictureUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.nickname}님,',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '오늘도 반짝이는 하루 보내세요!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
