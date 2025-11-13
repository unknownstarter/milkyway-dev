import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_status.dart';
import '../../../memos/domain/models/memo.dart';
import 'dart:developer';

class BookRepository {
  final SupabaseClient _client;

  BookRepository(this._client);

  Future<List<Book>> getRecentBooks() async {
    final response = await _client
        .from('user_books')
        .select('''
          *,
          books (
            *
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(10);

    return response
        .map((item) => Book.fromJson({
              ...item['books'] as Map<String, dynamic>,
              'status': item['status'],
            }))
        .toList();
  }

  Future<Book> getBookDetail(String bookId) async {
    final response = await _client
        .from('books')
        .select('''
          *,
          user_books!inner (
            status
          )
        ''')
        .eq('id', bookId)
        .eq('user_books.user_id', _client.auth.currentUser!.id)
        .single();

    return Book.fromJson({
      ...response,
      'status': response['user_books'][0]['status'],
    });
  }

  Future<List<Memo>> getBookMemos(String bookId) async {
    final response = await _client.from('memos').select('''
          *,
          book:books!book_id (
            title
          )
        ''').eq('book_id', bookId).order('created_at', ascending: false);

    return response
        .map((json) => Memo.fromJson({
              ...json,
              'book_title': json['book']['title'],
            }))
        .toList();
  }

  Future<List<Book>> getUserBooks() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client.from('user_books').select('''
            *,
            books (
              *
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return response
          .map((item) => Book.fromJson({
                ...item['books'] as Map<String, dynamic>,
                'status': item['status'],
              }))
          .toList();
    } catch (e) {
      log('Error getting user books: $e');
      rethrow;
    }
  }

  Future<Book> createBook({
    required String title,
    required String author,
    required String isbn,
    required String coverUrl,
    required String description,
    required String publisher,
    required String pubdate,
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
    } catch (e, stackTrace) {
      print('Error creating book: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      final response = await _client
          .from('user_books')
          .select('''
            *,
            books!inner (
              *
            )
          ''')
          .eq('user_id', _client.auth.currentUser!.id)
          .eq('books.isbn', isbn)
          .maybeSingle();

      if (response == null) return null;

      return Book.fromJson({
        ...response['books'] as Map<String, dynamic>,
        'status': response['status'],
      });
    } catch (e) {
      print('Error finding book by ISBN: $e');
      rethrow;
    }
  }

  Future<void> createUserBook({
    required String bookId,
    required String userId,
    required BookStatus status,
  }) async {
    await _client.from('user_books').insert({
      'book_id': bookId,
      'user_id': userId,
      'status': status.value,
    });
  }

  Future<void> updateBookStatus(String bookId, BookStatus status) async {
    await _client
        .from('user_books')
        .update({'status': status.value})
        .eq('book_id', bookId)
        .eq('user_id', _client.auth.currentUser!.id);
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

  String getCurrentUserId() {
    return _client.auth.currentUser!.id;
  }

  Future<void> createUserBookConnection(String bookId, String userId) async {
    await _client.from('user_books').insert({
      'book_id': bookId,
      'user_id': userId,
      'status': BookStatus.wantToRead.value,
    });
  }


}
