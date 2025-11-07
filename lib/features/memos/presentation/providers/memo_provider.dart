import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/memo_repository.dart';
import '../../domain/models/memo.dart';
import 'dart:io';
import 'dart:developer';
import '../../../../core/providers/supabase_client_provider.dart';

final memoRepositoryProvider = Provider((ref) {
  return MemoRepository(Supabase.instance.client);
});

final memoProvider = FutureProvider.family<Memo, String>((ref, memoId) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getMemoById(memoId);
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

    // 관련된 프로바이더들 새로고침
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(allMemosProvider);
    ref.invalidate(paginatedMemosProvider(params.bookId));
    ref.invalidate(paginatedMemosProvider(null));
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

  // 관련된 프로바이더들 새로고침
  ref.invalidate(bookMemosProvider(params.bookId));
  ref.invalidate(recentMemosProvider);
  ref.invalidate(homeRecentMemosProvider);
  ref.invalidate(allMemosProvider);
  ref.invalidate(paginatedMemosProvider(params.bookId));
  ref.invalidate(paginatedMemosProvider(null));
});

final deleteMemoProvider =
    FutureProvider.family<void, ({String memoId, String bookId})>(
  (ref, params) async {
    final repository = ref.watch(memoRepositoryProvider);
    await repository.deleteMemo(params.memoId);

    ref.invalidate(paginatedMemosProvider(params.bookId));
    ref.invalidate(bookMemosProvider(params.bookId));
    ref.invalidate(recentMemosProvider);
    ref.invalidate(homeRecentMemosProvider);
    ref.invalidate(allMemosProvider);
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
    loadInitialMemos();
  }

  Future<void> loadInitialMemos() async {
    state = const AsyncValue.loading();
    await _loadMemos();
  }

  Future<void> loadMoreMemos() async {
    if (!_hasMore) return;
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
    final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
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
