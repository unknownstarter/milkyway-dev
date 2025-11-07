import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/naver_book.dart';

class NaverBookService {
  final Dio _dio;
  static const _functionUrl =
      'https://hyjgfgzexvxhgfmqgiqu.supabase.co/functions/v1/search-books';

  NaverBookService() : _dio = Dio();

  Future<List<NaverBook>> searchBooks(String query) async {
    try {
      final response = await _dio.post(
        _functionUrl,
        data: {'query': query},
      );

      final List<dynamic> items = response.data['items'] ?? [];
      if (items.isEmpty) {
        return [];
      }

      return items.map((item) => NaverBook.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }
}

final naverBookServiceProvider = Provider((ref) {
  return NaverBookService();
});
