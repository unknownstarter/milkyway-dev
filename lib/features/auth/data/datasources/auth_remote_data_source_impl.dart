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
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              // Android는 google-services.json을 사용
              clientId: Platform.isIOS
                  ? '394691029555-cbbjdf7io2tec9004t3b31ons9r0a2g3.apps.googleusercontent.com'
                  : null,
            ),
        _supabase = supabase ?? Supabase.instance.client;

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // iOS/Android 공통 로직
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in cancelled');

      print('1. Google 계정 정보: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('2. Google 토큰: ${googleAuth.idToken?.substring(0, 50)}...');

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
        nonce: null,
      );
      print('3. Supabase 응답: ${res.user?.toJson()}');

      // 기존 사용자인지 확인
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();
      print('4. DB 유저 조회: ${existingUser}');

      if (existingUser == null) {
        print('5-1. 새 유저 데이터 준비: {');
        print('   id: ${res.user!.id},');
        print('   email: ${googleUser.email},');
        print('   nickname: ${googleUser.displayName},');
        print('   picture_url: ${googleUser.photoUrl}');
        print('}');

        await _supabase.from('users').upsert({
          'id': res.user!.id,
          'email': googleUser.email,
          'nickname': googleUser.displayName ?? '사용자',
          'picture_url': googleUser.photoUrl,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'auth_provider': 'google',
          'onboarding_completed': false,
        });
        print('5-2. 새 유저 생성 완료');
      }

      // 최신 사용자 정보 조회
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .single();
      print('6. 최종 유저 정보: ${userData['id']}');

      await _analytics.logLogin('google');

      return UserModel.fromJson(userData);
    } catch (e) {
      print('❌ 로그인 실패 상세: ${e.toString()}');
      throw Exception('Google 로그인 실패: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not logged in');

      print(
          'getCurrentUser - session: ${_supabase.auth.currentSession?.toJson()}');
      print(
          'getCurrentUser - currentUser: ${_supabase.auth.currentUser?.toJson()}');

      final userData =
          await _supabase.from('users').select().eq('id', userId).single();
      return UserModel.fromJson(userData);
    } catch (e) {
      print('getCurrentUser 실패: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      final rawNonce = _supabase.auth.generateRawNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      // 사용자 정보 확인 및 생성
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();

      if (existingUser == null) {
        // Apple은 두 번째 로그인부터 이름/이메일을 제공하지 않으므로,
        // 첫 로그인 시 저장해야 함
        final String nickname = [credential.givenName, credential.familyName]
            .where((name) => name != null)
            .join(' ');

        await _supabase.from('users').upsert({
          'id': res.user!.id,
          'email': credential.email,
          'nickname': nickname.isNotEmpty ? nickname : '사용자',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'auth_provider': 'apple',
        });
      }

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', res.user!.id)
          .single();

      await _analytics.logLogin('apple');

      return UserModel.fromJson(userData);
    } catch (e) {
      print('❌ Apple 로그인 실패: ${e.toString()}');
      throw Exception('Apple 로그인 실패: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Edge Function 호출
      await _supabase.functions.invoke(
        'delete-user',
        body: {'user_id': userId},
      );

      // 로컬 로그아웃
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ 계정 삭제 중 오류가 발생했습니다: $e');
      throw Exception('계정 삭제 중 오류가 발생했습니다.');
    }
  }
}
