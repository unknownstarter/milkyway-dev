import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/book_search_provider.dart';
import '../providers/book_register_provider.dart';
import '../screens/book_detail_screen.dart';
import '../../domain/models/naver_book.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';

class BookSearchScreen extends ConsumerStatefulWidget {
  const BookSearchScreen({super.key});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        ref.read(searchBooksProvider.notifier).searchBooks(query);
      }
    });
  }

  void _onBookTap(BuildContext context, NaverBook book) async {
    await ref.read(analyticsProvider).logButtonClick(
          'book_select',
          'book_search_screen',
        );
    final repository = ref.read(bookRepositoryProvider);
    final existingBook = await repository.findBookByIsbn(book.isbn);

    if (existingBook != null) {
      // 책이 있으면 사용자 연결 여부 확인
      final hasConnection = await repository.hasUserBookConnection(
          existingBook.id, repository.getCurrentUserId());

      if (hasConnection && context.mounted) {
        // 이미 연결된 책이면 스낵바 표시
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final snackBar = SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '이미 저장한 책이에요. 책의 상세페이지로 이동하시겠습니까?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: '이동',
            textColor: Colors.black,
            backgroundColor: Color(0xFF00FF62),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookDetailScreen(bookId: existingBook.id),
                ),
                (route) => route.isFirst,
              );
            },
          ),
          backgroundColor: Color(0xFF002912),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
        scaffoldMessenger.showSnackBar(snackBar);
        return;
      }
    }

    final shouldRegister = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3A3A3A),
                ),
                child: const Center(
                  child: Icon(
                    Icons.book_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '책 등록',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${book.title}을(를) 내 책장에 저장하시겠습니까?',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '예',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '아니오',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldRegister == true && context.mounted) {
      try {
        final registeredBook =
            await ref.read(bookRegisterProvider.notifier).registerBook(book);
        if (registeredBook != null && context.mounted) {
          await ref
              .read(analyticsProvider)
              .logBookRegistered(registeredBook.id, registeredBook.title);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(bookId: registeredBook.id),
            ),
            (route) => route.isFirst,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('책 등록에 실패했습니다: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        print('Error registering book: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchBooksProvider);

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '책 검색',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '책 제목 또는 작가 이름으로 검색',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade800),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                ),
              ),
            ),
            Expanded(
              child: searchState.when(
                data: (books) {
                  if (books.isEmpty && searchController.text.isNotEmpty) {
                    return const Center(
                      child: Text(
                        '검색 결과가 없습니다',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return InkWell(
                          onTap: () => _onBookTap(context, book),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  book.coverUrl,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.book),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book.author,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${book.publisher} · ${book.pubdate}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (book.description.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        book.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '검색 중 오류가 발생했습니다\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
