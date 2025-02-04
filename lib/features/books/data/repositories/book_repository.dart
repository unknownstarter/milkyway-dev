import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';

class BookRepository {
  final SupabaseClient _client;

  BookRepository(this._client);

  String getCurrentUserId() {
    return _client.auth.currentUser!.id;
  }

  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      final response =
          await _client.from('books').select().eq('isbn', isbn).maybeSingle();

      if (response == null) return null;
      return Book.fromJson(response);
    } catch (e) {
      print('Error finding book by ISBN: $e');
      rethrow;
    }
  }

  Future<Book> createBook({
    required String title,
    required String author,
    required String isbn,
    String? coverUrl,
    String? description,
    String? publisher,
    String? pubdate,
  }) async {
    try {
      final response = await _client
          .from('books')
          .insert({
            'title': title,
            'author': author,
            'isbn': isbn,
            'cover_url': coverUrl,
            'description': description,
            'publisher': publisher,
            'pubdate': pubdate,
          })
          .select()
          .single();

      return Book.fromJson(response);
    } catch (e) {
      print('Error creating book: $e');
      rethrow;
    }
  }

  Future<void> createUserBookConnection(String bookId, String userId) async {
    await _client.from('user_books').insert({
      'book_id': bookId,
      'user_id': userId,
      'status': '읽고 싶은',
    });
  }

  Future<bool> hasUserBookConnection(String bookId, String userId) async {
    final response = await _client
        .from('user_books')
        .select()
        .eq('book_id', bookId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }
}
