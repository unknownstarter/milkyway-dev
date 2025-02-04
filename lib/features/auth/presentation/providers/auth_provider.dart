import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:whatif_milkyway_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:whatif_milkyway_app/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../home/presentation/providers/selected_book_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  Future<void> _handleUserSignIn(User user) async {
    final existingUser =
        await _supabase.from('users').select().eq('id', user.id).maybeSingle();

    if (existingUser == null) {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'nickname': user.nickname,
        'picture_url': user.pictureUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    await getCurrentUser();
  }

  Future<void> signOut() async {
    try {
      // 구글 로그인 캐시 제거
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Supabase 로그아웃
      await _supabase.auth.signOut();

      // 모든 provider 초기화
      ref.invalidate(userBooksProvider);
      ref.invalidate(recentBooksProvider);
      ref.invalidate(recentMemosProvider);
      ref.invalidate(selectedBookIdProvider);
      ref.invalidate(paginatedMemosProvider(null)); // 전체 메모 목록

      // 상태 초기화
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        state = const AsyncValue.data(null);
        return null;
      }

      final userId = session.user.id;
      final userData =
          await _supabase.from('users').select().eq('id', userId).single();
      final user = User.fromJson(userData);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      // 디버그용 로그는 유지
      print('Error in getCurrentUser: $e');

      // 사용자에게는 일반적인 메시지 표시
      state = AsyncValue.error('로그인이 필요합니다.', st);
      return null;
    }
  }

  Future<String> _uploadProfileImage(String filePath) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      // 기존 이미지가 있다면 삭제
      try {
        final oldImageUrl = state.value?.pictureUrl;
        if (oldImageUrl != null) {
          final oldFileName = oldImageUrl.split('/').last;
          await _supabase.storage
              .from('profile_images')
              .remove(['$userId/$oldFileName']);
        }
      } catch (e) {
        print('기존 이미지 삭제 실패: $e');
      }

      // 새 이미지 업로드
      await _supabase.storage.from('profile_images').upload(fileName, file);

      // 업로드된 이미지의 URL 가져오기
      final imageUrl = _supabase.storage
          .from('profile_images')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1년 유효

      return imageUrl;
    } catch (e) {
      throw '이미지 업로드에 실패했습니다: $e';
    }
  }

  Future<void> updateProfile({String? nickname, String? imagePath}) async {
    state = const AsyncValue.loading();
    try {
      String? newPictureUrl;

      // 새 이미지가 선택되었다면 업로드
      if (imagePath != null) {
        newPictureUrl = await _uploadProfileImage(imagePath);
      }

      // 닉네임 중복 체크
      if (nickname != null) {
        final duplicateCheck = await _supabase
            .from('users')
            .select()
            .eq('nickname', nickname)
            .neq('id', _supabase.auth.currentUser!.id)
            .maybeSingle();

        if (duplicateCheck != null) {
          throw '이미 사용 중인 닉네임입니다.';
        }
      }

      // 프로필 업데이트
      final updates = {
        if (nickname != null) 'nickname': nickname,
        if (newPictureUrl != null) 'picture_url': newPictureUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', _supabase.auth.currentUser!.id);

      await getCurrentUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> checkOnboardingStatus() async {
    try {
      final userData = await _supabase
          .from('users')
          .select('onboarding_completed')
          .eq('id', _supabase.auth.currentUser!.id)
          .single();

      return userData['onboarding_completed'] ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> updateOnboardingStatus({required bool completed}) async {
    try {
      await _supabase.from('users').update({
        'onboarding_completed': completed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _supabase.auth.currentUser!.id);

      // 상태 업데이트 후 현재 사용자 정보 리프레시
      await getCurrentUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  @Deprecated('Use updateOnboardingStatus instead')
  Future<void> completeOnboarding() async {
    await updateOnboardingStatus(completed: true);
  }

  Future<String> getSignedUrl(String path) async {
    try {
      final signedUrl = await _supabase.storage
          .from('profile_images')
          .createSignedUrl(path.split('/').last, 60 * 60 * 24 * 365); // 1년 유효
      return signedUrl;
    } catch (e) {
      throw '프로필 이미지 URL을 가져오는데 실패했습니다.';
    }
  }

  Future<void> setDefaultProfileImage() async {
    try {
      final signedUrl = await _supabase.storage
          .from('profile_images')
          .createSignedUrl('default_profile.png', 60 * 60 * 24 * 365);

      await _supabase.from('users').update({'picture_url': signedUrl}).eq(
          'id', _supabase.auth.currentUser!.id);

      await getCurrentUser();
    } catch (e) {
      throw '기본 프로필 이미지 설정에 실패했습니다.';
    }
  }

  Future<void> deleteAccount() async {
    try {
      // 구글 로그인 캐시 제거
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Supabase 계정 삭제
      await _supabase.rpc('delete_user');
      await _supabase.auth.signOut();

      // 모든 provider 초기화
      ref.invalidate(userBooksProvider);
      ref.invalidate(recentBooksProvider);
      ref.invalidate(recentMemosProvider);
      ref.invalidate(selectedBookIdProvider);
      ref.invalidate(paginatedMemosProvider(null)); // 전체 메모 목록

      // 상태 초기화
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final platform = Platform.isIOS ? 'ios' : 'android';

      final versionData = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .single();

      final minVersion = versionData['min_version'] as String;
      final forceUpdate = versionData['force_update'] as bool;

      if (forceUpdate || _compareVersions(currentVersion, minVersion) < 0) {
        throw '새로운 버전이 있습니다. 업데이트가 필요합니다.';
      }
    } catch (e, st) {
      // 503 에러인 경우 무시하고 계속 진행
      if (e.toString().contains('503')) {
        return;
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final v1Part = v1Parts.length > i ? v1Parts[i] : 0;
      final v2Part = v2Parts.length > i ? v2Parts[i] : 0;
      if (v1Part != v2Part) return v1Part.compareTo(v2Part);
    }
    return 0;
  }
}
