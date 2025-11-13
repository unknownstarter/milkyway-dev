import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';
import '../../../home/domain/models/book.dart';
import '../../../home/domain/models/book_status.dart';
import '../../../home/data/repositories/book_repository.dart';
import '../../../home/presentation/providers/book_provider.dart';
import 'user_books_provider.dart';

class BookDetailController extends StateNotifier<AsyncValue<Book>> {
  final String bookId;
  final BookRepository _repository;
  final Ref _ref;

  BookDetailController({
    required this.bookId,
    required BookRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.loading()) {
    loadBook();
  }

  Future<void> loadBook() async {
    state = const AsyncValue.loading();
    try {
      final book = await _repository.getBookDetail(bookId);
      state = AsyncValue.data(book);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(BookStatus status) async {
    try {
      await _repository.updateBookStatus(bookId, status);
      // Books 스크린의 userBooksProvider도 갱신
      _ref.invalidate(userBooksProvider);
      await loadBook();
    } catch (e) {
      log('Error updating status: $e');
    }
  }
}

final bookDetailProvider = StateNotifierProvider.family<BookDetailController,
    AsyncValue<Book>, String>(
  (ref, bookId) => BookDetailController(
    bookId: bookId,
    repository: ref.watch(bookRepositoryProvider),
    ref: ref,
  ),
);
