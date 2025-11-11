import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/memo_list.dart';
import '../../../../core/presentation/widgets/empty_book_card.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/presentation/widgets/common_app_bar.dart';
import '../../../../core/presentation/widgets/add_floating_action_button.dart';

class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: const CommonAppBar(title: '메모'),
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
