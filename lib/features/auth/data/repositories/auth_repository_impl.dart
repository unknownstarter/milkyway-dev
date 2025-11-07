import 'package:dartz/dartz.dart';
import 'package:whatif_milkyway_app/core/errors/failures.dart';
import 'package:whatif_milkyway_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();

      // 실제 인증 성공 여부 확인
      if (userModel.id.isNotEmpty) {
        // UserModel을 User로 변환
        final user = User(
          id: userModel.id,
          email: userModel.email,
          nickname: userModel.nickname,
          pictureUrl: userModel.pictureUrl,
          createdAt: userModel.createdAt,
          updatedAt: userModel.updatedAt,
          onboardingCompleted: userModel.onboardingCompleted,
        );
        return Right(user);
      } else {
        return Left(AuthFailure('인증에 실패했습니다.'));
      }
    } catch (e) {
      // 명확한 인증 실패 케이스만 AuthFailure로 처리
      if (e.toString().contains('Google sign in cancelled') ||
          e.toString().contains('Failed to get user info')) {
        return Left(AuthFailure(e.toString()));
      }
      // 그 외의 예외는 무시하고 성공으로 처리 (이미 인증은 된 상태)
      final currentUserResult = await getCurrentUser();
      return currentUserResult.fold(
        (failure) => Left(failure),
        (user) => user != null ? Right(user) : Left(AuthFailure('사용자 정보를 가져올 수 없습니다.')),
      );
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    try {
      final userModel = await remoteDataSource.signInWithApple();
      // UserModel을 User로 변환
      final user = User(
        id: userModel.id,
        email: userModel.email,
        nickname: userModel.nickname,
        pictureUrl: userModel.pictureUrl,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
        onboardingCompleted: userModel.onboardingCompleted,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure());
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      if (userModel == null) return const Right(null);
      
      // UserModel을 User로 변환
      final user = User(
        id: userModel.id,
        email: userModel.email,
        nickname: userModel.nickname,
        pictureUrl: userModel.pictureUrl,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
        onboardingCompleted: userModel.onboardingCompleted,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthFailure());
    }
  }
}
