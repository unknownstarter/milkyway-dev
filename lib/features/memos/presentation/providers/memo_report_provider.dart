import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_report_repository.dart';
import '../../domain/models/report_reason.dart';
import 'memo_provider.dart'; // paginatedPublicBookMemosProvider import
import 'dart:developer' as developer;

final memoReportRepositoryProvider = Provider((ref) {
  return MemoReportRepository(Supabase.instance.client);
});

/// 사용자가 숨긴 메모 ID 목록 (캐시)
/// 
/// 신고한 메모는 자동으로 숨겨지므로, 숨긴 메모 목록만 조회하면 됩니다.
final hiddenMemoIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repository = ref.watch(memoReportRepositoryProvider);
  try {
    return await repository.getHiddenMemoIds();
  } catch (e) {
    developer.log('숨긴 메모 ID 조회 실패: $e');
    return <String>{};
  }
});

/// 메모 신고 파라미터 타입 (bookId 추가)
typedef ReportMemoParams = ({
  String memoId,
  String bookId, // 메모 리스트 리로딩을 위해 필요
  ReportReason reason,
  String? description,
});

/// 메모 신고 Provider
final reportMemoProvider = FutureProvider.family<void, ReportMemoParams>(
  (ref, params) async {
    final repository = ref.watch(memoReportRepositoryProvider);
    await repository.reportMemo(
      memoId: params.memoId,
      reason: params.reason,
      description: params.description,
    );

    // 신고 후 캐시 무효화
    ref.invalidate(hiddenMemoIdsProvider);
    
    // 공개 메모 리스트 리로딩 (신고한 메모가 즉시 사라지도록)
    final notifier = ref.read(
      paginatedPublicBookMemosProvider(params.bookId).notifier,
    );
    notifier.loadInitialMemos();
  },
);
