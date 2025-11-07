import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/naver_book_service.dart';
import '../../domain/models/naver_book.dart';

final searchBooksProvider =
    StateNotifierProvider<BookSearchNotifier, AsyncValue<List<NaverBook>>>(
        (ref) {
  return BookSearchNotifier(
    service: ref.watch(naverBookServiceProvider),
  );
});

class BookSearchNotifier extends StateNotifier<AsyncValue<List<NaverBook>>> {
  final NaverBookService _service;

  BookSearchNotifier({required NaverBookService service})
      : _service = service,
        super(const AsyncValue.data([]));

  Future<void> searchBooks(String query) async {
    state = const AsyncValue.loading();
    try {
      final books = await _service.searchBooks(query);
      state = AsyncValue.data(books);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data([]);
  }
}
