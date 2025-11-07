import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/book_repository.dart';
import '../../domain/models/book.dart';

final bookRepositoryProvider = Provider((ref) {
  return BookRepository(Supabase.instance.client);
});

final recentBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  // 여기서 현재 로그인한 사용자의 ID를 기반으로 책을 조회해야 함
  return repository.getRecentBooks();
});
