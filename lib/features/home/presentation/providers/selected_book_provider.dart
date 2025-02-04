import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../providers/book_provider.dart';
import '../../domain/models/book.dart';

final selectedBookIdProvider = StateProvider<String?>((ref) => null);

final selectedBookProvider = Provider<Book?>((ref) {
  final selectedId = ref.watch(selectedBookIdProvider);
  final books = ref.watch(recentBooksProvider).value ?? [];

  if (selectedId == null || books.isEmpty) return null;
  return books.firstWhereOrNull((book) => book.id == selectedId);
});
