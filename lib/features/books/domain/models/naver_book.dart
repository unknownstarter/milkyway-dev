class NaverBook {
  final String title;
  final String author;
  final String isbn;
  final String coverUrl;
  final String description;
  final String publisher;
  final String pubdate;

  NaverBook({
    required this.title,
    required this.author,
    required this.isbn,
    required this.coverUrl,
    required this.description,
    required this.publisher,
    required this.pubdate,
  });

  factory NaverBook.fromJson(Map<String, dynamic> json) {
    final isbnList = json['isbn'].split(' ');
    final isbn = isbnList.length > 1 ? isbnList[1] : isbnList[0];

    return NaverBook(
      title: json['title'].replaceAll('<b>', '').replaceAll('</b>', ''),
      author: json['author'].replaceAll('<b>', '').replaceAll('</b>', ''),
      isbn: isbn,
      coverUrl: json['image'],
      description:
          json['description'].replaceAll('<b>', '').replaceAll('</b>', ''),
      publisher: json['publisher'],
      pubdate: json['pubdate'],
    );
  }
}
