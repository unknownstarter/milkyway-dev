import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});

final recentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});
