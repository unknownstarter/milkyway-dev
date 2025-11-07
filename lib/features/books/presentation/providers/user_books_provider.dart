import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/models/book.dart';
import '../../../home/presentation/providers/book_provider.dart';

final userBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getUserBooks();
});
