class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String? coverUrl;
  final String? description;
  final String? publisher;
  final String? pubdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.coverUrl,
    this.description,
    this.publisher,
    this.pubdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      isbn: json['isbn'],
      coverUrl: json['cover_url'],
      description: json['description'],
      publisher: json['publisher'],
      pubdate: json['pubdate'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
