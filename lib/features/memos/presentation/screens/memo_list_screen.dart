import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/memo_list.dart';
import '../../../../core/presentation/widgets/empty_book_card.dart';
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
          if (books.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 200),
                child: EmptyBookCard(),
              ),
            );
          }
          return const MemoList();
        },
      ),
      floatingActionButton: const AddFloatingActionButton(),
    );
  }
}
