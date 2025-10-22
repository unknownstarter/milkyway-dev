import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/models/book.dart';
import '../../../home/data/repositories/book_repository.dart';
import '../../domain/models/naver_book.dart';
import '../providers/user_books_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../home/presentation/providers/book_provider.dart'
    show recentBooksProvider;
import 'dart:developer';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(Supabase.instance.client);
});

final bookRegisterProvider =
    StateNotifierProvider<BookRegisterNotifier, AsyncValue<void>>((ref) {
  return BookRegisterNotifier(
    repository: ref.read(bookRepositoryProvider),
    ref: ref,
  );
});

class BookRegisterNotifier extends StateNotifier<AsyncValue<void>> {
  final BookRepository _repository;
  final Ref _ref;

  BookRegisterNotifier({
    required BookRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<Book?> registerBook(NaverBook naverBook) async {
    state = const AsyncValue.loading();
    final userId = _repository.getCurrentUserId();

    try {
      // 1. 기존 책 찾기
      final existingBook = await _repository.findBookByIsbn(naverBook.isbn);

      Book book;
      if (existingBook != null) {
        // 2. 기존 책이 있으면 user_books 연결만 생성
        await _repository.createUserBookConnection(existingBook.id, userId);
        book = existingBook;
      } else {
        // 3. 새 책 생성 후 user_books 연결
        book = await _repository.createBook(
          title: naverBook.title,
          author: naverBook.author,
          isbn: naverBook.isbn,
          coverUrl: naverBook.coverUrl,
          description: naverBook.description,
          publisher: naverBook.publisher,
          pubdate: naverBook.pubdate,
        );
        await _repository.createUserBookConnection(book.id, userId);
      }

      _ref.invalidate(userBooksProvider);
      _ref.invalidate(recentBooksProvider);

      state = const AsyncValue.data(null);
      return book;
    } catch (e, st) {
      log('Error in registerBook: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
