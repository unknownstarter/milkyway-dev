import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/book_detail_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../memos/presentation/widgets/memo_card.dart';
import '../../../../core/providers/analytics_provider.dart';

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
    final bookAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          '책 상세',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editBook(),
          ),
        ],
      ),
      body: bookAsync.when(
        data: (book) => _buildContent(book),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(book) {
    final memosAsync = ref.watch(bookMemosProvider(book.id));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 책 정보
          _buildBookInfo(book),
          const SizedBox(height: 24),
          
          // 상태 변경 버튼
          _buildStatusButton(book),
          const SizedBox(height: 24),
          
          // 메모 섹션
          _buildMemosSection(book, memosAsync),
        ],
      ),
    );
  }

  Widget _buildBookInfo(book) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 책 표지
              _buildBookCover(book),
              const SizedBox(width: 16),
              
              // 책 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    if (book.publisher.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.publisher,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
                // 상태
              _buildStatusChip(book.status),
            ],
          ),
          
          if (book.description != null && book.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              book.description,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookCover(book) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade900,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: book.coverUrl != null
            ? Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildBookPlaceholder(),
              )
            : _buildBookPlaceholder(),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Icon(
        Icons.book,
        color: Colors.grey,
        size: 32,
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color statusColor;
    switch (status) {
      case '읽고 싶은':
        statusColor = Colors.orange;
        break;
      case '읽는 중':
        statusColor = const Color(0xFF48FF00);
        break;
      case '읽음':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildStatusButton(book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _changeStatus(book),
          icon: const Icon(Icons.swap_horiz, color: Colors.black),
          label: const Text(
            '상태 변경',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF48FF00),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemosSection(book, memosAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                '메모',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addMemo(book),
                icon: const Icon(Icons.add, color: Color(0xFF48FF00)),
                label: const Text(
                  '메모 추가',
                  style: TextStyle(
                    color: Color(0xFF48FF00),
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        memosAsync.when(
          data: (memos) => _buildMemosList(memos),
          loading: () => _buildMemosLoading(),
          error: (error, stack) => _buildMemosError(error),
        ),
      ],
    );
  }

  Widget _buildMemosList(List<dynamic> memos) {
    if (memos.isEmpty) {
      return _buildEmptyMemos();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: memos.map((memo) => _buildMemoItem(memo)).toList(),
      ),
    );
  }

  Widget _buildMemoItem(dynamic memo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MemoCard(
        memo: memo,
        onTap: () => _viewMemo(memo),
      ),
    );
  }

  Widget _buildMemosLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF48FF00),
        ),
      ),
    );
  }

  Widget _buildMemosError(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '메모를 불러올 수 없습니다: $error',
        style: const TextStyle(
          color: Colors.red,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildEmptyMemos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.note_add,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 메모가 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 메모를 작성해보세요',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF48FF00),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '책 정보를 불러올 수 없습니다',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _editBook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('책 편집 기능은 준비 중입니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _changeStatus(book) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('상태 변경 기능은 준비 중입니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _addMemo(book) {
    context.push('/memos/create?bookId=${book.id}');
  }

  void _viewMemo(memo) {
    context.push('/memos/detail/${memo.id}');
  }
}