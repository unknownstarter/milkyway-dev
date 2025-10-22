import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer';
import '../../../home/domain/models/book.dart';
import '../../../home/data/repositories/book_repository.dart';
import '../../../home/presentation/providers/book_provider.dart';

class BookDetailController extends StateNotifier<AsyncValue<Book>> {
  final String bookId;
  final BookRepository _repository;

  BookDetailController({
    required this.bookId,
    required BookRepository repository,
  })  : _repository = repository,
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

  Future<void> updateStatus(String status) async {
    try {
      await _repository.updateBookStatus(bookId, status);
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
  ),
);
