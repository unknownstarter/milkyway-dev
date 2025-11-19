import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:whatif_milkyway_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:whatif_milkyway_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import 'dart:developer';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final analytics = ref.watch(analyticsProvider);
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(analytics: analytics),
  );
}

@riverpod
class Auth extends _$Auth {
  final _supabase = Supabase.instance.client;

  @override
  FutureOr<User?> build() async {
    // 초기화 시 현재 사용자 가져오기
    return await getCurrentUser();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      await result.fold(
        (failure) async =>
            state = AsyncValue.error(failure, StackTrace.current),
        (user) async {
          await _handleUserSignIn(user);
          final currentUser = await getCurrentUser();
          state = AsyncValue.data(currentUser);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authRepositoryProvider).signInWithApple();
      await result.fold(
        (failure) async =>
            state = AsyncValue.error(failure, StackTrace.current),
        (user) async {
          await _handleUserSignIn(user);
          final currentUser = await getCurrentUser();
          state = AsyncValue.data(currentUser);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // 세션 갱신 시도 (만료되기 전에 자동 갱신)
      await _refreshSessionIfNeeded();
      
      final session = _supabase.auth.currentSession;
      if (session?.user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', session!.user.id)
          .maybeSingle();

      if (response == null) return null;

      return User.fromJson(response);
    } catch (e) {
      log('Error getting current user: $e');
      return null;
    }
  }

  /// 세션이 만료되기 전에 자동으로 갱신
  /// Refresh token을 사용하여 최대 1개월까지 세션 유지 가능
  Future<void> _refreshSessionIfNeeded() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      // 세션이 만료되기 5분 전에 갱신
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().toUtc();
        final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(
          expiresAt * 1000,
          isUtc: true,
        );
        final timeUntilExpiry = expiresAtDateTime.difference(now);

        // 만료되기 5분 전이면 갱신 시도
        if (timeUntilExpiry.inMinutes < 5) {
          log('세션 갱신 시도 (만료까지 ${timeUntilExpiry.inMinutes}분 남음)');
          await _supabase.auth.refreshSession();
          log('세션 갱신 완료');
        }
      }
    } catch (e) {
      log('세션 갱신 실패: $e');
      // 세션 갱신 실패는 무시 (다음 요청 시 다시 시도)
    }
  }

  Future<void> _handleUserSignIn(User user) async {
    try {
      // 사용자 정보가 이미 존재하는지 확인
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // 새 사용자 등록
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'nickname': user.nickname,
          'picture_url': user.pictureUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // 기존 사용자 정보 업데이트
        await _supabase.from('users').update({
          'email': user.email,
          'nickname': user.nickname,
          'picture_url': user.pictureUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
    } catch (e) {
      log('Error handling user sign in: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? nickname,
    String? pictureUrl,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nickname != null) updates['nickname'] = nickname;
      if (pictureUrl != null) {
        // 빈 문자열은 null로 처리 (이미지 제거)
        updates['picture_url'] = pictureUrl.isEmpty ? null : pictureUrl;
      }

      await _supabase.from('users').update(updates).eq('id', currentUser.id);

      // 상태 새로고침
      final updatedUser = await getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      // 사용자 데이터 삭제
      await _supabase.from('users').delete().eq('id', currentUser.id);
      
      // 계정 삭제
      await _supabase.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool get isSignedIn => _supabase.auth.currentUser != null;
  
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> checkAppVersion() async {
    // TODO: 앱 버전 체크 로직 구현
    // 현재는 빈 구현으로 두어 에러 방지
  }

  Future<bool> checkOnboardingStatus() async {
    final user = await getCurrentUser();
    return user?.onboardingCompleted ?? false;
  }

  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      await _supabase.from('users').update({
            'onboarding_completed': completed,
            'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      // 상태 새로고침
      final updatedUser = await getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      log('Error updating onboarding status: $e');
      state = AsyncValue.error(e, st);
    }
  }
}
