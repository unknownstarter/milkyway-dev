import 'package:flutter/material.dart';
import '../../../home/domain/models/book.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookGridItem({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
              child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  book.coverUrl ?? 'https://picsum.photos/200/300',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade900,
            child: const Icon(
              Icons.book,
              color: Colors.grey,
              size: 32,
                      ),
                    ),
        ),
      ),
    );
  }
}
