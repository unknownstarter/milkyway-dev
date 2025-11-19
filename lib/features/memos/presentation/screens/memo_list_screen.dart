import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/memo_list.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/presentation/widgets/add_floating_action_button.dart';

class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent, // Material 3에서 스크롤 시 색상 변경 방지
        elevation: 0,
        title: const Text(
          'My Memo',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            height: 28 / 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // MainShell에서 이미 bottomNavigationBar를 제공하므로 제거
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFECECEC)),
        ),
        error: (err, stack) => Center(
          child: SelectableText.rich(
            TextSpan(text: '에러: $err', style: TextStyle(color: Colors.red)),
          ),
        ),
        data: (books) {
          // 책이 없어도 MemoList를 표시하여 필터 버튼과 빈 상태 메시지 표시
          // bookId를 null로 명시적으로 전달하여 모든 메모를 가져옴
          return const MemoList(bookId: null);
        },
      ),
      floatingActionButton: const AddFloatingActionButton(),
    );
  }
}
