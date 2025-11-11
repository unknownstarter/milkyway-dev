# Milkyway App - 개발자 규칙 (Developer Rules)

## 📋 개발 가이드라인

**최종 업데이트:** 2025-11-11  
**적용 대상:** 모든 개발자  
**버전:** 1.2.0

## 🎯 핵심 원칙

### 1. 코드 품질 우선
- **단순명료한 코드** 작성
- **복잡한 로직보다는 명확한 코드** 선호
- **일관성 있는 코딩 스타일** 유지
- **불필요한 추상화 지양**

### 2. 사용자 경험 중심
- **성능 최적화** 우선
- **직관적인 UI/UX** 구현
- **에러 처리** 철저히
- **로딩 상태** 명확히 표시

## 🏗️ 아키텍처 규칙

### Clean Architecture 적용
```
lib/
├── core/                    # 공통 기능
│   ├── config/             # 설정
│   ├── errors/             # 에러 처리
│   ├── presentation/       # 공통 UI
│   ├── providers/          # 공통 Provider
│   ├── router/             # 라우팅
│   ├── services/           # 서비스
│   ├── theme/              # 테마
│   ├── usecases/           # 유스케이스
│   └── utils/              # 유틸리티
└── features/               # 기능별 모듈
    ├── auth/              # 인증
    ├── books/             # 책 관리
    ├── memos/             # 메모 관리
    └── home/              # 홈 화면
```

### 모듈 구조
```
features/[feature]/
├── data/                  # 데이터 계층
│   ├── datasources/       # 데이터 소스
│   ├── models/           # 데이터 모델
│   └── repositories/     # 리포지토리 구현
├── domain/               # 도메인 계층
│   ├── entities/         # 엔티티
│   ├── models/           # 도메인 모델
│   └── repositories/     # 리포지토리 인터페이스
└── presentation/         # 프레젠테이션 계층
    ├── providers/        # 상태 관리
    ├── screens/          # 화면
    └── widgets/          # 위젯
```

## 🎨 디자인 시스템

### 색상 규칙
```dart
// 주요 색상
const Color primaryBackground = Color(0xFF181818);    // 다크 그레이 (기본 배경)
const Color cardBackground = Color(0xFF1A1A1A);       // 다크 그레이 (카드 배경)
const Color navigationBarBackground = Color(0xFF2C2C2C); // 네비게이션 바 배경
const Color accentColor = Color(0xFF48FF00);           // 형광 초록
const Color primaryText = Color(0xFFFFFFFF);          // 흰색
const Color secondaryText = Color(0xFF9CA3AF);        // 그레이
const Color snackbarBackground = Color(0xFF242424);    // 스낵바 배경 (통일)
```

### 타이포그래피 규칙
```dart
// Pretendard 폰트 사용
const TextStyle titleStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle bodyStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Colors.white,
);
```

### 레이아웃 규칙
```dart
// 패딩 규칙
const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20);
const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16);

// 반경 규칙
const double cardRadius = 12.0;
const double buttonRadius = 12.0;

// 간격 규칙
const double smallSpacing = 8.0;
const double mediumSpacing = 16.0;
const double largeSpacing = 32.0;

// 피그마 디자인 기반 간격 (책 상세 페이지)
const double appBarToBookInfo = 28.0;        // 앱바와 책 정보 사이
const double bookTitleToAuthor = 24.0;      // 책 제목과 작가 사이
const double authorToPublisher = 2.0;       // 작가와 출판사 사이
const double bookInfoToStatus = 32.0;        // 책 정보와 상태 버튼 사이
const double statusToDescription = 32.0;     // 상태 버튼과 책 소개 타이틀 사이
const double descriptionTitleToContent = 20.0; // 책 소개 타이틀과 내용 사이
const double moreButtonToMemoTitle = 40.0;   // 더보기 버튼과 책 메모 타이틀 사이
const double memoTitleToFilter = 20.0;      // 책 메모 타이틀과 필터 버튼 사이
const double filterToFirstMemo = 32.0;       // 필터 버튼과 첫 번째 메모 카드 사이
```

## 🔧 코딩 규칙

### 1. 함수형 프로그래밍 우선
```dart
// ✅ 좋은 예
Widget _buildBookCard(Book book) {
  return Container(
    child: Text(book.title),
  );
}

// ❌ 나쁜 예
Widget _buildBookCard(Book book) {
  setState(() {
    // 상태 변경 로직
  });
  return Container(
    child: Text(book.title),
  );
}
```

### 2. const 생성자 사용
```dart
// ✅ 좋은 예
const Text(
  'Hello World',
  style: TextStyle(fontSize: 16),
);

// ❌ 나쁜 예
Text(
  'Hello World',
  style: TextStyle(fontSize: 16),
);
```

### 3. 명확한 변수명 사용
```dart
// ✅ 좋은 예
final isLoading = false;
final selectedBookId = 'book_123';
final memoList = <Memo>[];

// ❌ 나쁜 예
final flag = false;
final id = 'book_123';
final list = <Memo>[];
```

### 4. 에러 처리
```dart
// ✅ 좋은 예
try {
  final result = await apiCall();
  return result;
} catch (e) {
  print('API 호출 실패: $e');
  rethrow;
}

// ❌ 나쁜 예
final result = await apiCall(); // 에러 처리 없음
return result;
```

## 📱 UI/UX 규칙

### 0. 피그마 디자인 준수 (2025-11-07 추가)
- **피그마 좌표 기반 간격 적용** - 모든 간격은 피그마 디자인 파일의 좌표를 기준으로 설정
- **정확한 간격 측정** - 피그마에서 요소 간 거리를 정확히 측정하여 적용
- **일관된 색상 사용** - 피그마에 정의된 색상 값을 정확히 사용
- **반응형 레이아웃** - LayoutBuilder를 사용하여 화면 크기에 맞게 조정

### 1. 스낵바 색상 통일 (2025-11-07 추가)
```dart
// ✅ 모든 스낵바는 일관된 색상 사용
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('메시지'),
    backgroundColor: const Color(0xFF242424), // 통일된 색상
  ),
);
```

### 2. 책 소개 더보기 버튼 규칙 (2025-11-07 추가)
```dart
// ✅ 180자 이상일 때만 "더보기" 버튼 표시
final shouldShowMoreButton = description.length > 180 && !_isDescriptionExpanded;

// ✅ 탭 시 전체 텍스트 확장, 닫기 버튼 없음
// ✅ 화면을 나갔다가 다시 들어오면 초기 상태로 복귀
```

### 3. 빈 상태 처리 규칙 (2025-11-07 추가)
```dart
// ✅ 빈 상태는 항상 가운데 정렬
// ✅ 가능한 경우 탭 이벤트 추가 (관련 페이지로 이동)
Widget _buildEmptyState() {
  return Center(
    child: GestureDetector(
      onTap: () => context.push('/related-page'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('아직 메모가 없습니다'),
        ],
      ),
    ),
  );
}
```

### 4. 반응형 디자인
```dart
// 화면 크기별 대응
Widget _buildResponsiveLayout(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 600) {
    return _buildTabletLayout();
  } else {
    return _buildMobileLayout();
  }
}
```

### 2. 로딩 상태 처리
```dart
// AsyncValue 사용
Widget _buildContent(AsyncValue<List<Book>> booksAsync) {
  return booksAsync.when(
    data: (books) => _buildBookList(books),
    loading: () => _buildLoadingState(),
    error: (error, stack) => _buildErrorState(error),
  );
}
```

### 3. 이미지 처리
```dart
// 네트워크 이미지 로딩
Widget _buildNetworkImage(String imageUrl) {
  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return _buildLoadingIndicator();
    },
    errorBuilder: (context, error, stack) {
      return _buildErrorPlaceholder();
    },
  );
}
```

## 🔄 상태 관리 규칙

### 1. Riverpod 사용
```dart
// Provider 정의
@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    return await _repository.getBooks();
  }
  
  Future<void> addBook(Book book) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addBook(book);
      ref.invalidateSelf();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### 2. Provider 최적화
```dart
// select 사용으로 불필요한 리빌드 방지
final selectedBook = ref.watch(bookListProvider.select(
  (books) => books.value?.firstWhere((book) => book.id == selectedId),
));
```

## 🧪 테스트 규칙

### 1. 단위 테스트
```dart
// 테스트 파일명: [파일명]_test.dart
// 예: book_repository_test.dart

void main() {
  group('BookRepository', () {
    test('should return books when getBooks is called', () async {
      // Given
      final repository = BookRepository(mockClient);
      
      // When
      final result = await repository.getBooks();
      
      // Then
      expect(result, isA<List<Book>>());
    });
  });
}
```

### 2. 위젯 테스트
```dart
void main() {
  testWidgets('should display book list', (tester) async {
    // Given
    await tester.pumpWidget(MyApp());
    
    // When
    await tester.pumpAndSettle();
    
    // Then
    expect(find.byType(ListView), findsOneWidget);
  });
}
```

## 📦 패키지 관리

### 1. 의존성 추가 규칙
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # 상태 관리
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # 네비게이션
  go_router: ^12.1.3
  
  # 백엔드
  supabase_flutter: ^2.0.3
  
  # 인증
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^5.0.0
```

### 2. 버전 관리
- **메이저 버전:** 호환성 깨지는 변경
- **마이너 버전:** 새로운 기능 추가
- **패치 버전:** 버그 수정

## 🚀 성능 최적화

### 1. 이미지 최적화
```dart
// 이미지 캐싱
Widget _buildCachedImage(String url) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (context, url) => _buildLoadingIndicator(),
    errorWidget: (context, url, error) => _buildErrorPlaceholder(),
  );
}
```

### 2. 리스트 최적화
```dart
// ListView.builder 사용
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return _buildItem(items[index]);
  },
);
```

### 3. 메모리 관리
```dart
// 컨트롤러 해제
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## 🔒 보안 규칙

### 1. API 키 관리
```dart
// .env 파일 사용
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

### 2. 사용자 데이터 보호
```dart
// 민감한 정보 로깅 금지
print('User ID: ${user.id}'); // ✅ OK
print('User Password: ${user.password}'); // ❌ 금지
```

## 📝 문서화 규칙

### 1. 코드 주석
```dart
/// 사용자 인증을 처리하는 클래스
/// 
/// Google, Apple 로그인을 지원하며
/// Supabase와 연동하여 사용자 정보를 관리합니다.
class AuthService {
  /// Google 로그인을 수행합니다
  /// 
  /// [returns] 로그인 성공 시 사용자 정보, 실패 시 null
  Future<User?> signInWithGoogle() async {
    // 구현
  }
}
```

### 2. README 작성
```markdown
# Feature Name

## 개요
기능에 대한 간단한 설명

## 사용법
```dart
// 사용 예시
```

## 주의사항
- 주의할 점들
- 제한사항들
```

## 🔄 코드 리뷰 규칙

### 1. 리뷰 체크리스트
- [ ] 코드 스타일 준수
- [ ] 에러 처리 구현
- [ ] 성능 최적화
- [ ] 테스트 코드 작성
- [ ] 문서화 완료

### 2. 승인 기준
- **코드 품질:** 높음
- **테스트 커버리지:** 80% 이상
- **성능:** 요구사항 충족
- **보안:** 취약점 없음

## 🚨 **중요: 레포지토리 관리**

### 📁 **레포지토리 구조**
```
unknownstarter/
├── milkyway/           # 🏭 프로덕션 레포지토리 (원래)
└── milkyway-dev/       # 🛠️ 개발 레포지토리 (새로 생성)
```

### 🔄 **개발 워크플로우**
1. **개발 작업:** `milkyway-dev` 레포지토리에서 진행
2. **완성 후:** `milkyway` 레포지토리로 병합
3. **배포:** `milkyway` 레포지토리에서 프로덕션 배포

### 🎯 **현재 작업 레포지토리**
```bash
# ⚠️ 중요: 항상 이 레포지토리에서 작업
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev
```

### 📋 **레포지토리별 용도**
| 레포지토리 | 용도 | 상태 | 작업 내용 |
|------------|------|------|-----------|
| **milkyway** | 프로덕션 | 대기 | 완성된 코드 병합 대기 |
| **milkyway-dev** | 개발 | 활성 | 모든 개발 작업 진행 |

### ⚠️ **주의사항**
- **절대 `milkyway` 레포지토리에서 직접 개발 금지**
- **모든 개발 작업은 `milkyway-dev`에서만 진행**
- **완성 후에만 `milkyway`로 병합**

## 🏗️ 리팩토링 규칙 (2025-11-11 추가)

### 1. 파일 크기 관리
- **단일 파일 최대 권장 크기**: 500줄 이하
- **초과 시 위젯 분리**: 기능별로 별도 파일로 분리
- **목표**: 각 파일이 단일 책임을 가지도록 구성

### 2. 위젯 분리 원칙
```dart
// ✅ 좋은 예: 위젯을 별도 파일로 분리
// widgets/reading_books_section.dart
class ReadingBooksSection extends ConsumerWidget {
  // ...
}

// ❌ 나쁜 예: 모든 위젯을 한 파일에
class HomeScreen extends ConsumerStatefulWidget {
  // 1000줄 이상의 코드...
}
```

### 3. 모듈화 가이드라인
- **재사용 가능한 위젯**: `widgets/` 디렉토리에 분리
- **화면별 위젯**: `screens/` 디렉토리에 유지
- **공통 위젯**: `core/presentation/widgets/`에 배치
- **Delegate 클래스**: 별도 파일로 분리 (예: `reading_section_delegate.dart`)

### 4. 오버플로우 방지 규칙 (2025-11-11 추가)
```dart
// ✅ 좋은 예: 이중 제한으로 오버플로우 완전 방지
SizedBox(
  height: maxHeight, // 외부 제한
  child: ClipRect(
    clipBehavior: Clip.hardEdge,
    child: SizedBox(
      height: maxHeight, // 내부 제한
      child: child,
    ),
  ),
)

// ✅ 좋은 예: 즉시 전환으로 오버플로우 구간 회피
static const double _expandedDisplayThreshold = 0.001; // 거의 0일 때만 표시
static const double _transitionThreshold = 0.01; // 1% 진행 시 즉시 전환

// ❌ 나쁜 예: 단일 제한만 사용
SizedBox(
  height: currentHeight, // 동적 높이로 인한 오버플로우 가능
  child: child,
)
```

### 5. 상태 동기화 규칙 (2025-11-11 추가)
```dart
// ✅ 좋은 예: ScrollController 리스너로 자동 동기화
_scrollController.addListener(_onScrollChanged);

void _onScrollChanged() {
  if (_scrollController.position.pixels < 10) {
    // 맨 위로 돌아올 때 동기화
    _synchronizePageController();
  }
}

// ❌ 나쁜 예: 수동 동기화 (누락 가능)
// 사용자가 직접 스크롤을 올려야만 동기화됨
```

### 6. 리팩토링 체크리스트
리팩토링 전에 다음을 확인하세요:
- [ ] 기존 기능이 100% 동작하는가?
- [ ] 파일 크기가 500줄 이하인가?
- [ ] 위젯이 재사용 가능한가?
- [ ] 단일 책임 원칙을 준수하는가?
- [ ] 오버플로우가 발생하지 않는가?
- [ ] 상태 동기화가 올바르게 작동하는가?

---

**문서 작성일:** 2025-11-11  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2025-12-11
