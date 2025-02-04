import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/memo.dart';
import '../../data/repositories/memo_repository.dart' as memo;
import '../providers/memo_provider.dart';

class MemoFormParams {
  final String bookId;
  final Memo? initialMemo;

  MemoFormParams({
    required this.bookId,
    this.initialMemo,
  });
}

class MemoFormController extends StateNotifier<AsyncValue<void>> {
  final memo.MemoRepository _repository;
  final String bookId;
  final Memo? initialMemo;
  final Ref ref;

  final pageController = TextEditingController();
  final contentController = TextEditingController();

  MemoFormController({
    required memo.MemoRepository repository,
    required this.bookId,
    required this.ref,
    this.initialMemo,
  })  : _repository = repository,
        super(const AsyncValue.data(null)) {
    if (initialMemo != null) {
      pageController.text = initialMemo!.page?.toString() ?? '';
      contentController.text = initialMemo!.content;
    }
  }

  Future<bool> saveMemo() async {
    if (contentController.text.isEmpty) return false;

    state = const AsyncValue.loading();

    try {
      final page = pageController.text.isNotEmpty
          ? int.parse(pageController.text)
          : null;

      if (initialMemo != null) {
        await _repository.updateMemo(
          memoId: initialMemo!.id,
          content: contentController.text,
          page: page,
        );
      } else {
        print(
            'Creating memo with: bookId=$bookId, content=${contentController.text}, page=$page');
        await _repository.createMemo(
          bookId: bookId,
          content: contentController.text,
          page: page,
        );
      }

      ref.invalidate(bookMemosProvider(bookId));
      ref.invalidate(recentMemosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('Error saving memo: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteMemo() async {
    if (initialMemo == null) return false;

    state = const AsyncValue.loading();

    try {
      await _repository.deleteMemo(initialMemo!.id);
      ref.invalidate(bookMemosProvider(bookId));
      ref.invalidate(recentMemosProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    contentController.dispose();
    super.dispose();
  }
}

final memoFormControllerProvider = StateNotifierProvider.family<
    MemoFormController, AsyncValue<void>, MemoFormParams>((ref, params) {
  final repository = ref.watch(memo.memoRepositoryProvider);
  return MemoFormController(
    repository: repository,
    bookId: params.bookId,
    ref: ref,
    initialMemo: params.initialMemo,
  );
});
