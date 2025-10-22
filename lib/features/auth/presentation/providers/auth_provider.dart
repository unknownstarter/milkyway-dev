import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:whatif_milkyway_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:whatif_milkyway_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import 'dart:developer';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
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
    return null;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      await result.fold(
        (failure) async => state = AsyncValue.error(failure, StackTrace.current),
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
        (failure) async => state = AsyncValue.error(failure, StackTrace.current),
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
      if (pictureUrl != null) updates['picture_url'] = pictureUrl;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser.id);

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
}