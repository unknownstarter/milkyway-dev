import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../memos/presentation/screens/memo_create_screen.dart';
import '../../../memos/presentation/widgets/memo_card.dart';
import '../providers/book_detail_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import '../../../home/presentation/providers/selected_book_provider.dart';
import '../../../../core/presentation/widgets/star_background_scaffold.dart';
import '../../../books/presentation/providers/book_status_update_provider.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;
  final bool isFromRegistration;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.isFromRegistration = false,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('book_detail_screen');
  }

  @override
  Widget build(BuildContext context) {
    final bookId = widget.bookId;
    final bookAsync = ref.watch(bookDetailProvider(bookId));

    return StarBackgroundScaffold(
      appBar: AppBar(
        title: const Text(
          '책 상세',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              ref.read(bookStatusUpdateFlagProvider.notifier).state = true;
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
            ref.invalidate(recentBooksProvider);
            ref.invalidate(recentMemosProvider);
            ref.invalidate(homeRecentMemosProvider);
            ref.read(selectedBookIdProvider.notifier).state = widget.bookId;
          },
        ),
      ),
      body: bookAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (book) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              book.coverUrl ?? 'https://picsum.photos/200/300',
                              width: 120,
                              height: 174,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  book.author,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${book.publisher} · ${book.pubdate}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (book.description != null &&
                        book.description!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '책 소개',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          book.description!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ref.watch(paginatedMemosProvider(bookId)).when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) =>
                              Center(child: Text('Error: $err')),
                          data: (memos) {
                            if (memos.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    '아직 작성된 메모가 없습니다.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: memos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) =>
                                  MemoCard(memo: memos[index]),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final bookState =
                              ref.watch(bookDetailProvider(bookId));
                          return ElevatedButton(
                            onPressed: () {
                              _showStatusBottomSheet(context, ref);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  bookState.value?.status == '읽고 싶은'
                                      ? const Color(0xFFF33E3E)
                                      : bookState.value?.status == '읽는 중'
                                          ? const Color(0xFFF0B000)
                                          : bookState.value?.status == '완독'
                                              ? const Color(0xFF0410F1)
                                              : Colors.white,
                              foregroundColor: bookState.value?.status == null
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: bookState.value?.status == null
                                    ? const BorderSide(color: Colors.black)
                                    : BorderSide.none,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(bookState.value?.status ?? book.status),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(analyticsProvider).logButtonClick(
                                'create_memo',
                                'book_detail_screen',
                              );
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoCreateScreen(
                                bookId: widget.bookId,
                                bookTitle: book.title,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4117EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('메모 작성하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            '읽기 상태',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            onTap: () async {
              await ref.read(analyticsProvider).logButtonClick(
                    'status_want_to_read',
                    'book_detail_screen',
                  );
              await ref.read(analyticsProvider).logBookStatusChanged(
                    widget.bookId,
                    '읽고 싶은',
                  );
              ref
                  .read(bookDetailProvider(widget.bookId).notifier)
                  .updateStatus('읽고 싶은');
              ref.read(bookStatusUpdateFlagProvider.notifier).state = true;
              Navigator.pop(bottomSheetContext);
            },
            title: const Text(
              '읽고 싶은',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            onTap: () async {
              await ref.read(analyticsProvider).logButtonClick(
                    'status_reading',
                    'book_detail_screen',
                  );
              ref
                  .read(bookDetailProvider(widget.bookId).notifier)
                  .updateStatus('읽는 중');
              ref.read(bookStatusUpdateFlagProvider.notifier).state = true;
              Navigator.pop(bottomSheetContext);
            },
            title: const Text(
              '읽는 중',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ListTile(
            onTap: () async {
              await ref.read(analyticsProvider).logButtonClick(
                    'status_finished',
                    'book_detail_screen',
                  );
              ref
                  .read(bookDetailProvider(widget.bookId).notifier)
                  .updateStatus('완독');
              ref.read(bookStatusUpdateFlagProvider.notifier).state = true;
              Navigator.pop(bottomSheetContext);
            },
            title: const Text(
              '완독',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
