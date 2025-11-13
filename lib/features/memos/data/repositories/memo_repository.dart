import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_visibility.dart';
import 'dart:developer';

class MemoRepository {
  final SupabaseClient _client;

  MemoRepository(this._client);

  Future<List<Memo>> getRecentMemos() async {
    final response = await _client
        .from('memos')
        .select('''
          *,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(2);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  Future<List<Memo>> getBookMemos(String bookId) async {
    final response = await _client.from('memos').select('''
          *,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''').eq('book_id', bookId).order('created_at', ascending: false);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  Future<void> createMemo({
    required String bookId,
    required String content,
    int? page,
    String? imageUrl,
  }) async {
    log('Creating memo with imageUrl: $imageUrl');
    await _client.from('memos').insert({
      'book_id': bookId,
      'user_id': _client.auth.currentUser!.id,
      'content': content,
      'page': page,
      'image_url': imageUrl,
      'visibility': MemoVisibility.private.value,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateMemo({
    required String memoId,
    required String content,
    int? page,
    String? imageUrl,
  }) async {
    await _client.from('memos').update({
      'content': content,
      'page': page,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', memoId);
  }

  Future<void> deleteMemo(String memoId) async {
    await _client.from('memos').delete().eq('id', memoId);
  }

  Future<Memo> getMemoById(String memoId) async {
    final response = await _client
        .from('memos')
        .select('''
          *,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''')
        .eq('id', memoId)
        .single();

    return Memo.fromJson(response);
  }

  Future<List<Memo>> getAllMemos() async {
    final response = await _client
        .from('memos')
        .select('''
          *,
          books (
            id,
            title,
            author,
            cover_url
          ),
          users!user_id (
            nickname,
            picture_url
          )
        ''')
        .eq('user_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return response.map((json) => Memo.fromJson(json)).toList();
  }

  Future<List<Memo>> getPaginatedMemos({
    required int limit,
    required int offset,
    String? bookId,
  }) async {
    var query = _client.from('memos').select('''
      *,
      books (
        id,
        title,
        author,
        cover_url
      ),
      users!user_id (
        nickname,
        picture_url
      )
    ''').eq('user_id', _client.auth.currentUser!.id);

    if (bookId != null && bookId.isNotEmpty) {
      query = query.eq('book_id', bookId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    return response.map((json) => Memo.fromJson(json)).toList();
  }
}

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});
