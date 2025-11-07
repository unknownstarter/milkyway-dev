import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_remote_data_source_impl.dart';
import '../../../../core/providers/analytics_provider.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return AuthRemoteDataSourceImpl(analytics: analytics);
});
