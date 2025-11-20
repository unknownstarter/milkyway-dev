import 'dart:developer' as developer;
import 'dart:convert';

/// 간단한 인메모리 응답 캐시
/// 
/// Edge Function 응답을 캐싱하여 동일한 요청 시 네트워크 호출을 줄임
class ResponseCache {
  static final ResponseCache _instance = ResponseCache._internal();
  factory ResponseCache() => _instance;
  ResponseCache._internal();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 5); // 기본 TTL: 5분

  /// 캐시 키 생성
  /// JSON 직렬화를 사용하여 안전하고 일관된 키 생성
  String _generateKey(String functionName, Map<String, dynamic> body) {
    // 키를 정렬하여 일관된 키 생성
    final sortedBody = Map.fromEntries(
      body.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    // JSON 직렬화를 사용하여 안전한 키 생성
    final jsonString = jsonEncode(sortedBody);
    return '$functionName:$jsonString';
  }

  /// 캐시에서 데이터 가져오기
  T? get<T>(String functionName, Map<String, dynamic> body) {
    final key = _generateKey(functionName, body);
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    // TTL 확인
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      developer.log('캐시 만료: $key', name: 'ResponseCache');
      return null;
    }

    developer.log('캐시 히트: $key', name: 'ResponseCache');
    return entry.data as T;
  }

  /// 캐시에 데이터 저장
  void set<T>(
    String functionName,
    Map<String, dynamic> body,
    T data, {
    Duration? ttl,
  }) {
    final key = _generateKey(functionName, body);
    final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
    
    _cache[key] = _CacheEntry<T>(
      data: data,
      expiresAt: expiresAt,
    );
    
    developer.log('캐시 저장: $key (만료: $expiresAt)', name: 'ResponseCache');
    
    // 캐시 크기 제한 (100개 이상이면 오래된 항목 제거)
    if (_cache.length > 100) {
      _evictOldEntries();
    }
  }

  /// 오래된 캐시 항목 제거
  void _evictOldEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (now.isAfter(entry.value.expiresAt)) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    // 여전히 100개 이상이면 가장 오래된 항목 제거
    if (_cache.length > 100) {
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      
      final toRemove = sortedEntries.length - 100;
      for (var i = 0; i < toRemove; i++) {
        _cache.remove(sortedEntries[i].key);
      }
    }
    
    developer.log('캐시 정리: ${keysToRemove.length}개 항목 제거', name: 'ResponseCache');
  }

  /// 특정 함수의 캐시 무효화
  /// [body]가 제공되면 특정 요청만 무효화, 없으면 해당 함수의 모든 캐시 무효화
  /// [bookId]가 제공되면 해당 책의 캐시만 무효화 (선택적 최적화)
  void invalidate(
    String functionName, {
    Map<String, dynamic>? body,
    String? bookId,
  }) {
    if (body != null) {
      final key = _generateKey(functionName, body);
      _cache.remove(key);
      developer.log('캐시 무효화: $key', name: 'ResponseCache');
    } else if (bookId != null) {
      // 특정 bookId의 캐시만 무효화 (더 효율적)
      final keysToRemove = _cache.keys
          .where((key) {
            // JSON에서 book_id 추출하여 비교
            try {
              final jsonPart = key.substring(functionName.length + 1);
              final decoded = jsonDecode(jsonPart) as Map<String, dynamic>;
              return decoded['book_id'] == bookId;
            } catch (e) {
              // JSON 파싱 실패 시 함수 이름으로만 필터링
              return key.startsWith('$functionName:');
            }
          })
          .toList();
      
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      
      developer.log(
        '캐시 무효화: $functionName (bookId: $bookId, ${keysToRemove.length}개 항목)',
        name: 'ResponseCache',
      );
    } else {
      // 함수 이름으로 시작하는 모든 키 제거
      final keysToRemove = _cache.keys
          .where((key) => key.startsWith('$functionName:'))
          .toList();
      
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      
      developer.log(
        '캐시 무효화: $functionName (${keysToRemove.length}개 항목)',
        name: 'ResponseCache',
      );
    }
  }

  /// 전체 캐시 클리어
  void clear() {
    final count = _cache.length;
    _cache.clear();
    developer.log('캐시 전체 클리어: $count개 항목', name: 'ResponseCache');
  }
}

/// 캐시 엔트리
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({
    required this.data,
    required this.expiresAt,
  });
}

