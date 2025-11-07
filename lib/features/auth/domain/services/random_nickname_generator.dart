class RandomNicknameGenerator {
  static String generate() {
    const adjectives = ['반짝이는', '빛나는', '꿈꾸는', '생각하는', '읽는'];
    const nouns = ['독서가', '작가', '철학자', '예술가', '여행자'];

    final random = DateTime.now().millisecondsSinceEpoch;
    final adj = adjectives[random % adjectives.length];
    final noun = nouns[(random ~/ 1000) % nouns.length];

    return '$adj $noun';
  }
}
