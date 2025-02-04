import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/memo.dart';

class MemoRepository {
  final SupabaseClient _client;

  MemoRepository(this._client);

  Future<List<Memo>> getRecentMemos() async {
    final response = await _client.from('memos').select('''
          *,
          books (
            title
          )
        ''').order('created_at', ascending: false).limit(2);

    return response
        .map((json) => Memo.fromJson({
              ...json,
              'book_title': json['books']['title'],
            }))
        .toList();
  }

  Future<void> createMemo({
    required String bookId,
    required String content,
    int? page,
  }) async {
    await _client.from('memos').insert({
      'book_id': bookId,
      'content': content,
      'page': page,
      'visibility': 'private',
    });
  }

  Future<void> updateMemo({
    required String memoId,
    required String content,
    int? page,
  }) async {
    await _client.from('memos').update({
      'content': content,
      'page': page,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', memoId);
  }

  Future<void> deleteMemo(String memoId) async {
    await _client.from('memos').delete().eq('id', memoId);
  }
}
