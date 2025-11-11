import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import 'memo_card.dart';

class MemoList extends ConsumerStatefulWidget {
  final String? bookId;

  const MemoList({
    super.key,
    this.bookId,
  });

  @override
  ConsumerState<MemoList> createState() => _MemoListState();
}

class _MemoListState extends ConsumerState<MemoList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(paginatedMemosProvider(widget.bookId).notifier);
      if (notifier.hasMore) {
        notifier.loadMoreMemos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(paginatedMemosProvider(widget.bookId));

    return memosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFECECEC)),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (memos) {
        if (memos.isEmpty) {
          return const Center(
            child: Text(
              '등록한 책에서 메모를 남겨주세요 🙇‍♂️',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: memos.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == memos.length) {
              return ref
                      .read(paginatedMemosProvider(widget.bookId).notifier)
                      .hasMore
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFFECECEC),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            return MemoCard(memo: memos[index]);
          },
        );
      },
    );
  }
}
