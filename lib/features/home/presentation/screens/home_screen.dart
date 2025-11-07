import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/book.dart';
import '../../../memos/domain/models/memo.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/selected_book_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Reading 섹션을 위한 SliverPersistentHeaderDelegate
class _ReadingSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _ReadingSectionDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF181818),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_ReadingSectionDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late PageController _pageController;

  // 순환 표시할 문구 리스트
  static const List<String> _readingPrompts = [
    '오늘은 어떤 책을 보고 계신가요?',
    '지금 읽고 있는 책이 있나요?',
    '오늘의 독서는 어떤가요?',
    '어떤 책을 읽고 계신가요?',
    '지금 읽는 책이 궁금해요',
    '오늘도 좋은 책과 함께하시나요?',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.4);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userBooksAsync = ref.read(userBooksProvider);
    userBooksAsync.whenData((books) {
      if (books.isNotEmpty && ref.read(selectedBookIdProvider) == null) {
        // 빌드 완료 후 provider 수정
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedBookIdProvider.notifier).state = books[0].id;
          }
        });
      }
    });
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
      backgroundColor: const Color(0xFF181818),
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

    return CustomScrollView(
      slivers: [
        // 앱바 (고정)
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: _buildAppBar(),
        ),
        // 프로필 영역
        SliverToBoxAdapter(
          child: _buildProfileSection(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 34), // Figma: 프로필과 "읽고 있는 책" 타이틀 사이 34px
        ),

        // Reading 섹션 (Sticky 효과)
        SliverPersistentHeader(
          pinned: true,
          delegate: _ReadingSectionDelegate(
            child: _buildReadingSection(books),
            height: 20 + 16 + 147 + 20, // 제목 + 간격 + 책 높이 + 여유
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),

        // Memo 섹션
        SliverToBoxAdapter(
          child: _buildMemoSection(books),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // 하단 네비게이션 바 공간
        ),
      ],
    );
  }

  // 앱바 (상단 고정)
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo_horizontal.png',
        height: 37,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  // 프로필 이미지 위젯
  Widget _buildProfileAvatar(String? pictureUrl) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: pictureUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                pictureUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildProfileAvatarPlaceholder(),
              ),
            )
          : _buildProfileAvatarPlaceholder(),
    );
  }

  Widget _buildProfileAvatarPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF48FF00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.black,
        size: 20,
      ),
    );
  }

  // 프로필 영역 (앱바 아래)
  Widget _buildProfileSection() {
    final authAsync = ref.watch(authProvider);

    return Container(
      padding:
          const EdgeInsets.fromLTRB(20, 22, 20, 0), // Figma: 앱바와 프로필 사이 22px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지 (Avatar)
          authAsync.when(
            data: (user) => _buildProfileAvatar(user?.pictureUrl),
            loading: () => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF48FF00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            error: (_, __) => _buildProfileAvatarPlaceholder(),
          ),
          const SizedBox(width: 20),
          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                authAsync.when(
                  data: (user) => Text(
                    '${user?.nickname ?? 'User'}님,',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                  loading: () => const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                  error: (_, __) => const Text(
                    'User님,',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      height: 21.48 / 18,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘은 어떤 책을 보고 계신가요?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard',
                    height: 19.09 / 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingSection(List<Book> books) {
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    // 선택된 책 ID 설정 (빌드 완료 후)
    if (books.length == 1) {
      if (ref.read(selectedBookIdProvider) != books[0].id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(selectedBookIdProvider.notifier).state = books[0].id;
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "읽고 있는 책" 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '읽고 있는 책',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              height: 28 / 20, // lineHeight 28
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 책 스와이프
        SizedBox(
          height: 147, // Figma height
          child: books.length == 1
              ? _buildSingleBookView(books[0])
              : _buildBookSwipeView(books),
        ),
      ],
    );
  }

  // 단일 책 표시
  Widget _buildSingleBookView(Book book) {
    return Center(
      child: GestureDetector(
        onTap: () => context.push('/books/detail/${book.id}'),
        child: _buildBookCover(book, 104, 147, 1.0),
      ),
    );
  }

  // 여러 책 스와이프 뷰 (Figma 디자인)
  Widget _buildBookSwipeView(List<Book> books) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        ref.read(selectedBookIdProvider.notifier).state = books[index].id;
      },
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _buildAnimatedBookItem(books, index);
      },
    );
  }

  // 애니메이션이 적용된 책 아이템 (현재 페이지와의 거리에 따라 크기/opacity 조정)
  Widget _buildAnimatedBookItem(List<Book> books, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 0.0;
        if (_pageController.position.haveDimensions) {
          value = index.toDouble() - (_pageController.page ?? 0.0);
          value = (value * 0.4).clamp(-1.0, 1.0);
        }

        // 중앙에서의 거리 (0.0 = 중앙, 1.0 = 가장 멀리)
        final distance = value.abs().clamp(0.0, 1.0);

        // 크기 계산: 중앙일 때 1.0, 멀어질수록 0.64로 선형 보간 (67/104 ≈ 0.64)
        final scale = 1.0 - (distance * 0.36);

        // Opacity 계산: 중앙일 때 1.0, 멀어질수록 0.3으로 선형 보간
        final opacity = 1.0 - (distance * 0.7);

        // Transform으로 크기 조정 (중앙 정렬)
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.3, 1.0),
            child: Center(
              child: GestureDetector(
                onTap: () => context.push('/books/detail/${books[index].id}'),
                child: _buildBookCover(books[index], 104, 147, 1.0),
              ),
            ),
          ),
        );
      },
    );
  }

  // 책 표지 위젯
  Widget _buildBookCover(
      Book book, double width, double height, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? Image.network(
                  book.coverUrl!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: width,
                      height: height,
                      color: Colors.grey.shade900,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildBookPlaceholder(width, height),
                )
              : _buildBookPlaceholder(width, height),
        ),
      ),
    );
  }

  Widget _buildBookPlaceholder([double? width, double? height]) {
    return Container(
      width: width,
      height: height,
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
    if (books.isEmpty) {
      return _buildEmptyMemoState();
    }

    final selectedBookId = ref.watch(selectedBookIdProvider);
    if (selectedBookId == null) {
      // 선택된 책이 없으면 첫 번째 책 선택 (빌드 완료 후)
      final firstBook = books[0];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(selectedBookIdProvider.notifier).state = firstBook.id;
        }
      });
      return _buildEmptyMemoState();
    }

    final memosAsync = ref.watch(bookMemosProvider(selectedBookId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "내 메모" 제목
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '내 메모',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
              height: 28 / 20, // lineHeight 28
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final memo in memos) _buildMemoCard(memo),
        ],
      ),
    );
  }

  Widget _buildMemoCard(Memo memo) {
    final hasImage = memo.imageUrl != null && memo.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push('/memos/detail/${memo.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasImage
            ? _buildMemoCardWithImage(memo)
            : _buildMemoCardTextOnly(memo),
      ),
    );
  }

  // 텍스트만 있는 메모 카드 (354x110)
  Widget _buildMemoCardTextOnly(Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // Figma에서는 padding 없음
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메모 텍스트
          Text(
            memo.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 24 / 16, // lineHeight 24
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14), // 86 - 72 = 14
          // 하단 정보 (책 이름 + 페이지)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 책 이름
              Expanded(
                child: Text(
                  memo.bookTitle,
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16, // lineHeight 24
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 페이지
              if (memo.page != null)
                Text(
                  'p ${memo.page}',
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16, // lineHeight 24
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 이미지가 있는 메모 카드 (354x157)
  Widget _buildMemoCardWithImage(Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // Figma에서는 padding 없음
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 텍스트 + 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메모 텍스트 (왼쪽)
              Expanded(
                child: Text(
                  memo.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 24 / 16, // lineHeight 24
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15), // 간격
              // 메모 이미지 (오른쪽, 80x120)
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade900,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    memo.imageUrl!,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 120,
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
          ),
          const SizedBox(height: 13), // 133 - 120 = 13
          // 하단 정보 (책 이름 + 페이지)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 책 이름
              Expanded(
                child: Text(
                  memo.bookTitle,
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16, // lineHeight 24
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 페이지
              if (memo.page != null)
                Text(
                  'p ${memo.page}',
                  style: const TextStyle(
                    color: Color(0xFF838383),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w300,
                    height: 24 / 16, // lineHeight 24
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // 날짜 기반으로 문구 선택 (매일 다른 문구)
    final dayOfYear = DateTime.now()
        .difference(
          DateTime(DateTime.now().year, 1, 1),
        )
        .inDays;
    final promptIndex = dayOfYear % _readingPrompts.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _readingPrompts[promptIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/books/search'),
              child: Container(
                width: 104,
                height: 147,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.grey,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '책 등록하기',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SelectableText.rich(
          TextSpan(
            text: '에러: $error',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMemoState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '메모가 없습니다',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildEmptyMemosList() {
    final selectedBookId = ref.watch(selectedBookIdProvider);

    return GestureDetector(
      onTap: () {
        if (selectedBookId != null) {
          context.push('/memos/create?bookId=$selectedBookId');
        }
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildMemosLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '메모를 불러오는 중...',
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
      child: SelectableText.rich(
        TextSpan(
          text: '메모를 불러오는 중 오류가 발생했습니다: $error',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}
