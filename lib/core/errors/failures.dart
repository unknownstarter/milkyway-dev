import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {}

class NetworkFailure extends Failure {}

class AuthFailure extends Failure {
  final String? message;
  AuthFailure([this.message]);
}
