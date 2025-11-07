import 'package:dartz/dartz.dart';
import 'package:whatif_milkyway_app/core/errors/failures.dart';
import 'package:whatif_milkyway_app/core/usecases/usecase.dart';
import 'package:whatif_milkyway_app/features/auth/domain/entities/user.dart';
import 'package:whatif_milkyway_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) {
    return repository.signInWithGoogle();
  }
}
