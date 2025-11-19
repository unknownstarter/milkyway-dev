import 'memo_visibility.dart';

class Memo {
  final String id;
  final String userId;
  final String bookId;
  final String content;
  final int? page;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MemoVisibility visibility;
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
    // Supabase 조인 결과 처리: users는 객체 또는 배열일 수 있음
    Map<String, dynamic>? users;
    final usersData = json['users'];
    if (usersData != null) {
      if (usersData is List && usersData.isNotEmpty) {
        // 배열인 경우 첫 번째 요소 사용
        users = usersData[0] as Map<String, dynamic>?;
      } else if (usersData is Map<String, dynamic>) {
        // 객체인 경우 그대로 사용
        users = usersData;
      }
    }

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
      visibility: MemoVisibility.fromString(json['visibility']),
      bookTitle: json['books']['title'],
      books: json['books'] as Map<String, dynamic>,
      imageUrl: json['image_url'],
      userNickname: users?['nickname'],
      userAvatarUrl: users?['picture_url'],
    );
  }
}
