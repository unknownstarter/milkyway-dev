import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';
import 'dart:io';
import 'dart:developer';
import '../../../../core/providers/supabase_client_provider.dart';
import '../../../../core/utils/response_cache.dart';

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});

final memoProvider = FutureProvider.family<Memo?, String>((ref, memoId) async {
  try {
    final repository = ref.watch(memoRepositoryProvider);
    return await repository.getMemoById(memoId);
  } catch (e) {
    // 메모가 삭제되었거나 존재하지 않는 경우 null 반환
    log('메모 조회 실패 (삭제되었을 수 있음): $e');
    return null;
  }
});

final bookMemosProvider =
    FutureProvider.family<List<Memo>, String>((ref, bookId) async {
  if (bookId.isEmpty) return [];
  final repository = ref.watch(memoRepositoryProvider);
  try {
    return await repository.getBookMemos(bookId);
  } catch (e) {
    log('Error in bookMemosProvider: $e');
    return []; // 에러가 발생해도 빈 리스트를 반환
  }
});

/// 해당 책의 모든 공개 메모 가져오기 (다른 유저의 공개 메모 포함)
/// @deprecated 페이지네이션을 위해 paginatedPublicBookMemosProvider 사용 권장
final publicBookMemosProvider =
    FutureProvider.family<List<Memo>, String>((ref, bookId) async {
  if (bookId.isEmpty) return [];
  final repository = ref.watch(memoRepositoryProvider);
  try {
    return await repository.getPublicBookMemos(bookId);
  } catch (e) {
    log('Error in publicBookMemosProvider: $e');
    return []; // 에러가 발생해도 빈 리스트를 반환
  }
});

/// 해당 책의 공개 메모를 페이지네이션으로 가져오기 (다른 유저의 공개 메모 포함)
class PaginatedPublicBookMemosNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  final MemoRepository _repository;
  final String bookId;
  int _page = 0;
  static const int _limit = 10;
  bool _hasMore = true;
  bool _isLoading = false; // 중복 요청 방지 플래그

  PaginatedPublicBookMemosNotifier({
    required MemoRepository repository,
    required this.bookId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    loadInitialMemos();
  }

  Future<void> loadInitialMemos() async {
    if (!mounted || _isLoading) return;
    state = const AsyncValue.loading();
    _page = 0;
    _hasMore = true;
    _isLoading = true;
    try {
      await _loadMemos();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  Future<void> loadMoreMemos() async {
    // 이미 로딩 중이거나 더 이상 불러올 데이터가 없으면 중단
    if (_isLoading || !_hasMore || !mounted) return;
    
    _isLoading = true;
    _page++;
    try {
      await _loadMemos();
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  Future<void> _loadMemos() async {
    try {
      final memos = await _repository.getPaginatedPublicBookMemos(
        bookId: bookId,
        limit: _limit,
        offset: _page * _limit,
      );

      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;

      _hasMore = memos.length == _limit;

      if (_page == 0) {
        state = AsyncValue.data(memos);
      } else {
        final currentMemos = state.value ?? [];
        state = AsyncValue.data([...currentMemos, ...memos]);
      }
    } catch (e, st) {
      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;
      
      // 에러 발생 시 이전 페이지로 롤백
      if (_page > 0) {
        _page--;
      }
      
      state = AsyncValue.error(e, st);
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}

final paginatedPublicBookMemosProvider = StateNotifierProvider.family<
    PaginatedPublicBookMemosNotifier, AsyncValue<List<Memo>>, String>(
  (ref, bookId) => PaginatedPublicBookMemosNotifier(
    repository: ref.watch(memoRepositoryProvider),
    bookId: bookId,
  ),
);

final recentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});

final createMemoProvider =
    FutureProvider.family<void, ({String bookId, String content, int? page})>(
  (ref, params) async {
    final repository = ref.watch(memoRepositoryProvider);
    await repository.createMemo(
      bookId: params.bookId,
      content: params.content,
      page: params.page,
    );

    // 캐시 무효화 (특정 bookId만 무효화하여 효율성 향상)
    ResponseCache().invalidate('get-public-book-memos', bookId: params.bookId);

    // 관련된 프로바이더들 새로고침
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(allMemosProvider);
    ref.invalidate(paginatedMemosProvider(params.bookId));
    ref.invalidate(paginatedMemosProvider(null));
    ref.invalidate(paginatedPublicBookMemosProvider(params.bookId));
  },
);

final updateMemoProvider = FutureProvider.family<
    void,
    ({
      String memoId,
      String content,
      String bookId,
      int? page,
      String? imageUrl,
    })>((ref, params) async {
  final repository = ref.read(memoRepositoryProvider);
  final supabase = ref.read(supabaseClientProvider);

  // 기존 메모의 이미지가 있다면 삭제
  if (params.imageUrl == null) {
    try {
      final oldMemo = await supabase
          .from('memos')
          .select('image_url')
          .eq('id', params.memoId)
          .single();

      if (oldMemo['image_url'] != null) {
        final userId = supabase.auth.currentUser!.id;
        final oldFileName = '${userId}/${oldMemo['image_url'].split('/').last}';
        await supabase.storage.from('memo_images').remove([oldFileName]);
      }
    } catch (e) {
      log('기존 이미지 삭제 실패: $e');
    }
  }

  await repository.updateMemo(
    memoId: params.memoId,
    content: params.content,
    page: params.page,
    imageUrl: params.imageUrl,
  );

  // 캐시 무효화 (특정 bookId만 무효화하여 효율성 향상)
  ResponseCache().invalidate('get-public-book-memos', bookId: params.bookId);

  // 관련된 프로바이더들 새로고침
  ref.invalidate(memoProvider(params.memoId)); // 메모 상세 화면 갱신
  ref.invalidate(bookMemosProvider(params.bookId));
  ref.invalidate(recentMemosProvider);
  ref.invalidate(homeRecentMemosProvider);
  ref.invalidate(allMemosProvider);
  ref.invalidate(paginatedMemosProvider(params.bookId));
  ref.invalidate(paginatedMemosProvider(null));
  ref.invalidate(paginatedPublicBookMemosProvider(params.bookId));
});

final deleteMemoProvider =
    FutureProvider.family<void, ({String memoId, String bookId})>(
  (ref, params) async {
    final repository = ref.watch(memoRepositoryProvider);
    await repository.deleteMemo(params.memoId);

    // 캐시 무효화 (특정 bookId만 무효화하여 효율성 향상)
    ResponseCache().invalidate('get-public-book-memos', bookId: params.bookId);

    // 모든 관련 provider 무효화하여 UI 업데이트
    ref.invalidate(memoProvider(params.memoId)); // 메모 상세 화면 갱신 (null 반환하여 화면 닫기)
    ref.invalidate(paginatedMemosProvider(params.bookId));
    ref.invalidate(paginatedMemosProvider(null)); // 전체 메모 리스트도 무효화
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(allMemosProvider);
    ref.invalidate(paginatedPublicBookMemosProvider(params.bookId));
  },
);

final allMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getAllMemos();
});

final homeRecentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});

class PaginatedMemosNotifier extends StateNotifier<AsyncValue<List<Memo>>> {
  final MemoRepository _repository;
  final String? bookId;
  int _page = 0;
  static const int _limit = 10;
  bool _hasMore = true;

  PaginatedMemosNotifier({
    required MemoRepository repository,
    this.bookId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    // 생성자에서 즉시 로딩 시작
    // StateNotifier는 생성 시점에 mounted가 true이므로 안전함
    loadInitialMemos();
  }

  Future<void> loadInitialMemos() async {
    // mounted 체크 제거: StateNotifier는 생성 시점부터 mounted가 true
    state = const AsyncValue.loading();
    _page = 0;
    _hasMore = true;
    await _loadMemos();
  }

  Future<void> loadMoreMemos() async {
    if (!_hasMore || !mounted) return;
    _page++;
    await _loadMemos();
  }

  Future<void> _loadMemos() async {
    try {
      final memos = await _repository.getPaginatedMemos(
        limit: _limit,
        offset: _page * _limit,
        bookId: bookId,
      );

      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;

      _hasMore = memos.length == _limit;

      if (_page == 0) {
        state = AsyncValue.data(memos);
      } else {
        state = AsyncValue.data([
          ...state.value ?? [],
          ...memos,
        ]);
      }
    } catch (e, st) {
      // dispose된 후에는 state를 업데이트하지 않음
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  bool get hasMore => _hasMore;
}

final paginatedMemosProvider = StateNotifierProvider.family<
    PaginatedMemosNotifier, AsyncValue<List<Memo>>, String?>(
  (ref, bookId) => PaginatedMemosNotifier(
    repository: ref.watch(memoRepositoryProvider),
    bookId: bookId,
  ),
);

Future<String?> _uploadMemoImage(String filePath) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(filePath);

    await Supabase.instance.client.storage
        .from('memo_images')
        .upload(fileName, file);

    final imageUrl = Supabase.instance.client.storage
        .from('memo_images')
        .createSignedUrl(fileName, 60 * 60 * 24 * 365);

    return imageUrl;
  } catch (e) {
    log('이미지 업로드 실패: $e');
    return null;
  }
}

final createMemoWithImageProvider =
    StateNotifierProvider<CreateMemoNotifier, AsyncValue<void>>((ref) {
  return CreateMemoNotifier(ref.watch(memoRepositoryProvider));
});

class CreateMemoNotifier extends StateNotifier<AsyncValue<void>> {
  final MemoRepository _repository;

  CreateMemoNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createMemo({
    required String bookId,
    required String content,
    required String? imagePath,
    int? page,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _uploadMemoImage(imagePath);
      }

      await _repository.createMemo(
        bookId: bookId,
        content: content,
        page: page,
        imageUrl: imageUrl,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 메모 수정 이벤트를 위한 새로운 프로바이더 추가
final memoUpdateEventProvider = StateProvider<String?>((ref) => null);
