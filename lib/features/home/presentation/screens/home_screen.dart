import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../../../memos/domain/models/memo.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../providers/selected_book_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;
  int _currentBookIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBooksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: userBooksAsync.when(
          data: (books) => _buildContent(books),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildContent(List<Book> books) {
    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: 32),
          
          // Reading 섹션
          _buildReadingSection(books),
          const SizedBox(height: 32),
          
          // Memo 섹션
          _buildMemoSection(books),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF48FF00),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Alex',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
          const Spacer(),
          // Home 타이틀
          const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingSection(List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Reading',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBookIndex = index;
              });
              ref.read(selectedBookProvider.notifier).setSelectedBook(books[index]);
            },
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final isSelected = index == _currentBookIndex;
              
              return _buildBookCard(book, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(isSelected ? 1.0 : 0.9)
          ..translate(0.0, isSelected ? 0.0 : 10.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF48FF00).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                ? Image.network(
                    book.coverUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF48FF00),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('책 표지 이미지 로딩 실패: $error');
                      return _buildBookPlaceholder();
                    },
                  )
                : _buildBookPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(
          Icons.book,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildMemoSection(List<Book> books) {
    if (books.isEmpty || _currentBookIndex >= books.length) {
      return _buildEmptyMemoState();
    }

    final selectedBook = books[_currentBookIndex];
    final memosAsync = ref.watch(bookMemosProvider(selectedBook.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Memo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        const SizedBox(height: 16),
        memosAsync.when(
          data: (memos) => _buildMemosList(memos),
          loading: () => _buildMemosLoadingState(),
          error: (error, stack) => _buildMemosErrorState(error),
        ),
      ],
    );
  }

  Widget _buildMemosList(List<Memo> memos) {
    if (memos.isEmpty) {
      return _buildEmptyMemosList();
    }

    return Container(
      height: 200, // 고정 높이 설정
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: memos.length,
        itemBuilder: (context, index) {
          final memo = memos[index];
          return _buildMemoCard(memo);
        },
      ),
    );
  }

  Widget _buildMemoCard(Memo memo) {
    return GestureDetector(
      onTap: () => context.push('/memos/detail/${memo.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메모 이미지 (있는 경우)
          if (memo.imageUrl != null) ...[
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade900,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  memo.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade900,
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // 메모 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메모 텍스트
                Text(
                  memo.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // 하단 정보
                Row(
                  children: [
                    // 책 이름
                    Expanded(
                      child: Text(
                        memo.bookTitle,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 공개/비공개 상태
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: memo.visibility == 'public' 
                            ? const Color(0xFF48FF00).withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        memo.visibility == 'public' ? '공개' : '비공개',
                        style: TextStyle(
                          color: memo.visibility == 'public' 
                              ? const Color(0xFF48FF00)
                              : Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // 작성 시간
                    Text(
                      _formatTimeAgo(memo.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade800,
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.book_outlined,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No books yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first book to get started',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/books/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48FF00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ADD BOOK',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
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
            'Error: $error',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMemoState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'No memos available',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildEmptyMemosList() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'No memos for this book',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildMemosLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Loading memos...',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildMemosErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Error loading memos: $error',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}m ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}