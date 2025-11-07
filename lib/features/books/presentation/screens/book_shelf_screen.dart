import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/book_grid_item.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/presentation/widgets/empty_book_card.dart';
import '../../../../core/presentation/widgets/common_app_bar.dart';
import '../../../home/presentation/widgets/add_action_modal.dart';

class BookShelfScreen extends ConsumerWidget {
  const BookShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: const CommonAppBar(title: '책 목록'),
      // MainShell에서 이미 bottomNavigationBar를 제공하므로 제거
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
          return _BookGrid(books: books);
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

class _BookGrid extends StatelessWidget {
  final List<dynamic> books;
  const _BookGrid({required this.books});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.48,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookGridItem(
          book: book,
          onTap: () => context.push('/books/detail/${book.id}'),
        );
      },
    );
  }
}
