class Memo {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final int? page;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String visibility;
  final String bookTitle;
  final Map<String, dynamic> books;
  final String? imageUrl;
  final String? userNickname;
  final String? userAvatarUrl;

  Memo({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.content,
    this.page,
    required this.createdAt,
    this.updatedAt,
    required this.visibility,
    required this.bookTitle,
    required this.books,
    this.imageUrl,
    this.userNickname,
    this.userAvatarUrl,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>?;

    return Memo(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      content: json['content'],
      page: json['page'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      visibility: json['visibility'],
      bookTitle: json['books']['title'],
      books: json['books'] as Map<String, dynamic>,
      imageUrl: json['image_url'],
      userNickname: users?['nickname'],
      userAvatarUrl: users?['picture_url'],
    );
  }
}
