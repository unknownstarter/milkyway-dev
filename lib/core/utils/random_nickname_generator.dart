class RandomNicknameGenerator {
  static const List<String> _adjectives = [
    '즐거운',
    '행복한',
    '신나는',
    '따뜻한',
    '포근한',
    '밝은',
    '귀여운',
    '멋진',
    '예쁜',
    '착한',
    '슬기로운',
    '지혜로운',
    '씩씩한',
    '힘찬',
    '튼튼한',
    '새로운',
    '신선한',
    '상쾌한',
    '깔끔한',
    '산뜻한',
  ];

  static const List<String> _nouns = [
    '하늘',
    '바다',
    '구름',
    '별',
    '달',
    '나무',
    '꽃',
    '새',
    '나비',
    '고양이',
    '강아지',
    '토끼',
    '다람쥐',
    '거북이',
    '펭귄',
    '책',
    '연필',
    '공책',
    '도서관',
    '책장',
  ];

  static String generate() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final adjIndex = random % _adjectives.length;
    final nounIndex = (random ~/ 1000) % _nouns.length;

    return '${_adjectives[adjIndex]} ${_nouns[nounIndex]}';
  }
}
