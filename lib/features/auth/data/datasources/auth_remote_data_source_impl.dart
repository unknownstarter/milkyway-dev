import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whatif_milkyway_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:whatif_milkyway_app/features/auth/data/models/user_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../../core/services/analytics_service.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase;
  final AnalyticsService _analytics;

  AuthRemoteDataSourceImpl({
    required AnalyticsService analytics,
    GoogleSignIn? googleSignIn,
    SupabaseClient? supabase,
  })  : _analytics = analytics,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _supabase = supabase ?? Supabase.instance.client;

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      print('🔵 Google 로그인 시작...');
      
      // 기존 세션 정리
      await _googleSignIn.signOut();
      print('🔵 기존 세션 정리 완료');
      
      // Google 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google 로그인 취소됨');
        throw Exception('Google sign in cancelled');
      }

      print('🔵 Google 사용자 정보 획득: ${googleUser.email}');
      
      // Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔵 Google 인증 토큰 획득 완료');

      // Supabase 로그인
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        print('❌ Supabase 로그인 실패');
        throw Exception('Supabase authentication failed');
      }

      print('🔵 Supabase 로그인 성공: ${response.user!.id}');

      // 사용자 정보 생성
      final userModel = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        nickname: googleUser.displayName ?? '사용자',
        pictureUrl: googleUser.photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('✅ Google 로그인 완료: ${userModel.email}');
      return userModel;
    } catch (e) {
      print('❌ Google 로그인 실패: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      print('🍎 Apple 로그인 시작...');
      
      // Apple 로그인 요청
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        print('❌ Apple 로그인 취소됨');
        throw Exception('Apple sign in cancelled');
      }

      print('🍎 Apple 사용자 정보 획득: ${credential.userIdentifier}');
      
      // Supabase 로그인
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode,
      );

      if (response.user == null) {
        print('❌ Supabase 로그인 실패');
        throw Exception('Supabase authentication failed');
      }

      print('🍎 Supabase 로그인 성공: ${response.user!.id}');

      // 사용자 정보 생성
      final userModel = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        nickname: '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
        pictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('✅ Apple 로그인 완료: ${userModel.email}');
      return userModel;
    } catch (e) {
      print('❌ Apple 로그인 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      print('🚪 로그아웃 시작...');
      
      // Google 로그아웃
      await _googleSignIn.signOut();
      print('🔵 Google 로그아웃 완료');
      
      // Supabase 로그아웃
      await _supabase.auth.signOut();
      print('🔵 Supabase 로그아웃 완료');
      
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.user == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', session!.user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ 현재 사용자 정보 조회 실패: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    String? nickname,
    String? pictureUrl,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nickname != null) updates['nickname'] = nickname;
      if (pictureUrl != null) updates['picture_url'] = pictureUrl;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser.id);

      print('✅ 프로필 업데이트 완료');
    } catch (e) {
      print('❌ 프로필 업데이트 실패: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // 사용자 데이터 삭제
      await _supabase.from('users').delete().eq('id', currentUser.id);
      
      // 계정 삭제
      await _supabase.auth.signOut();
      
      print('✅ 계정 삭제 완료');
    } catch (e) {
      print('❌ 계정 삭제 실패: $e');
      rethrow;
    }
  }
}