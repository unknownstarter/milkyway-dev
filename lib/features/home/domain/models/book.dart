import 'book_status.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? pubdate;
  final BookStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String isbn;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.publisher,
    this.pubdate,
    this.status = BookStatus.wantToRead,
    required this.createdAt,
    required this.updatedAt,
    required this.isbn,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['cover_url'],
      description: json['description'],
      publisher: json['publisher'],
      pubdate: json['pubdate'],
      status: BookStatus.fromString(json['status']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      isbn: json['isbn'] ?? '',
    );
  }
}
