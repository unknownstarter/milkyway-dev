import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/report_reason.dart';
import 'dart:developer' as developer;

/// 메모 신고 Repository
/// 
/// 신고 기능과 숨김 메모 관리를 담당합니다.
class MemoReportRepository {
  final SupabaseClient _client;

  MemoReportRepository(this._client);

  /// 메모 신고
  /// 
  /// 신고 생성과 동시에 해당 메모를 사용자에게 숨깁니다.
  Future<void> reportMemo({
    required String memoId,
    required ReportReason reason,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      // 1. 신고 생성 (UNIQUE 제약조건으로 중복 신고 방지)
      // created_at, updated_at은 DB에서 자동으로 설정됨
      await _client.from('memo_reports').insert({
        'memo_id': memoId,
        'reporter_id': userId,
        'reason': reason.toValue(),
        'description': description?.trim().isEmpty == true ? null : description?.trim(),
      });

      // 2. 신고한 사용자에게 해당 메모 숨기기
      // UNIQUE 제약조건이 있으므로 중복 삽입 시 무시됨
      try {
        await _client.from('user_hidden_memos').insert({
          'user_id': userId,
          'memo_id': memoId,
        });
      } on PostgrestException catch (e) {
        // UNIQUE 제약조건 위반 (이미 숨겨진 메모인 경우) 무시
        if (e.code == '23505') {
          developer.log('메모가 이미 숨겨져 있음: $memoId');
        } else {
          rethrow;
        }
      }

      developer.log('메모 신고 완료: memoId=$memoId, reason=${reason.displayName}');
    } on PostgrestException catch (e) {
      // UNIQUE 제약조건 위반 (이미 신고한 경우)
      if (e.code == '23505') {
        developer.log('이미 신고한 메모입니다: $memoId');
        throw Exception('이미 신고한 메모입니다.');
      }
      developer.log('메모 신고 실패: $e');
      rethrow;
    } catch (e) {
      developer.log('메모 신고 실패: $e');
      rethrow;
    }
  }

  /// 사용자가 숨긴 메모 ID 목록 조회
  /// 
  /// 신고한 메모는 자동으로 숨겨지므로, 숨긴 메모 목록만 조회하면 됩니다.
  Future<Set<String>> getHiddenMemoIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return <String>{};
    }

    try {
      final response = await _client
          .from('user_hidden_memos')
          .select('memo_id')
          .eq('user_id', userId);

      return response.map((json) => json['memo_id'] as String).toSet();
    } catch (e) {
      developer.log('숨긴 메모 ID 조회 실패: $e');
      return <String>{};
    }
  }
}
