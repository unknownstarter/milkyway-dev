/// 앱 라우트 경로 상수
/// 
/// 타입 안전한 라우트 경로 관리
class AppRoutes {
  // 인증 관련
  static const splash = '/';
  static const login = '/login';
  
  // 온보딩
  static const onboardingNickname = '/onboarding/nickname';
  static const onboardingProfileImage = '/onboarding/profile-image';
  static const onboardingBookIntro = '/onboarding/book-intro';
  
  // 메인 앱 (ShellRoute 하위)
  static const home = '/home';
  static const books = '/books';
  static const bookShelf = '/books/shelf';
  static const bookDetail = '/books/detail';
  static const bookSearch = '/books/search';
  static const memos = '/memos';
  static const memoDetail = '/memos/detail';
  static const memoCreate = '/memos/create';
  static const memoEdit = '/memos/edit';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  
  // 라우트 경로 생성 헬퍼
  static String bookDetailPath(String bookId) => '$bookDetail/$bookId';
  static String memoDetailPath(String memoId) => '$memoDetail/$memoId';
  static String memoEditPath(String memoId) => '$memoEdit/$memoId';
  
  // 라우트 이름
  static const splashName = 'splash';
  static const loginName = 'login';
  static const onboardingNicknameName = 'onboarding-nickname';
  static const onboardingProfileImageName = 'onboarding-profile-image';
  static const onboardingBookIntroName = 'onboarding-book-intro';
  static const homeName = 'home';
  static const booksName = 'books';
  static const bookShelfName = 'book-shelf';
  static const bookDetailName = 'book-detail';
  static const bookSearchName = 'book-search';
  static const memosName = 'memos';
  static const memoDetailName = 'memo-detail';
  static const memoCreateName = 'memo-create';
  static const memoEditName = 'memo-edit';
  static const profileName = 'profile';
  static const profileEditName = 'profile-edit';
}
