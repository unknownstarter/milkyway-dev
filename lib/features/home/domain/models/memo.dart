class Memo {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final String visibility;
  final int? page;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String bookTitle;

  Memo({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    required this.visibility,
    this.page,
    required this.createdAt,
    this.updatedAt,
    required this.bookTitle,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      content: json['content'],
      visibility: json['visibility'],
      page: json['page'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      bookTitle: json['book_title'],
    );
  }
}
