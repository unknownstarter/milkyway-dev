import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/book_provider.dart';
import '../providers/selected_book_provider.dart';
import 'book_card.dart';

class RecentBooksSection extends ConsumerWidget {
  const RecentBooksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(recentBooksProvider);

    return booksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFECECEC)),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (books) {
        if (books.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 15),
                child: Text(
                  '새로운 책을 골라주세요 \ud83d\udc47',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/books/search'),
                child: Container(
                  height: 450,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: MediaQuery.of(context).size.width - 8,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.shade800,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '어떤 책을 읽고 싶나요? 🤔',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return PageView.builder(
          controller: PageController(
            viewportFraction: 0.8,
            initialPage: 0,
          ),
          padEnds: false,
          onPageChanged: (index) {
            ref.read(selectedBookIdProvider.notifier).state = books[index].id;
          },
          itemCount: books.length,
          itemBuilder: (context, index) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16.0 : 8.0,
                  right: 8.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: BookCard(
                      book: books[index],
                      onTap: () {
                        // 선택된 책 ID 업데이트
                        ref.read(selectedBookIdProvider.notifier).state =
                            books[index].id;
                        context.push('/books/detail/${books[index].id}');
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
