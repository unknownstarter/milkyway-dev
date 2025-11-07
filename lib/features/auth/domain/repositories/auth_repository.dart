import 'package:dartz/dartz.dart';
import 'package:whatif_milkyway_app/core/errors/failures.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithApple();
  Future<Either<Failure, void>> signOut();
}
