import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../books/presentation/providers/user_books_provider.dart';

final memoListLoaderProvider = AsyncNotifierProvider<MemoListLoaderNotifier, void>(MemoListLoaderNotifier.new);

class MemoListLoaderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    await load();
  }

  Future<void> load() async {
    try {
      ref.invalidate(userBooksProvider);
      await ref.read(userBooksProvider.future);
    } catch (e) {
      // 에러 무시(로딩 실패 시 화면에서 처리)
    }
  }
} 