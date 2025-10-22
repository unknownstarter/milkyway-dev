import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/memo_list.dart';
import '../../../../core/presentation/widgets/empty_book_card.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/presentation/widgets/common_app_bar.dart';
import '../../../../core/presentation/widgets/common_bottom_nav_bar.dart';
import '../../../home/presentation/widgets/add_action_modal.dart'; // AddActionModal import 경로 수정

class MemoListScreen extends ConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);
    return Scaffold(
      appBar: const CommonAppBar(title: '메모'),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/books/shelf'); break;
            case 2: context.go('/memos'); break;
            case 3: context.go('/profile'); break;
          }
        },
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => const AddActionModal(),
        ),
        backgroundColor: Color(0xFF4117EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
