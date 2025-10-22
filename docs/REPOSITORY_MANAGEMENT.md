# 🚨 **중요: 레포지토리 관리 가이드**

## 📋 개요

**Milkyway App**은 두 개의 레포지토리로 관리됩니다:
- **`milkyway`** - 프로덕션 레포지토리 (원래)
- **`milkyway-dev`** - 개발 레포지토리 (새로 생성)

## 🎯 **현재 작업 레포지토리**

### ⚠️ **중요: 항상 이 레포지토리에서 작업**
```bash
# 개발용 레포지토리 클론
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 📁 **레포지토리 구조**

```
unknownstarter/
├── milkyway/           # 🏭 프로덕션 레포지토리 (원래)
│   ├── main           # 프로덕션 브랜치
│   └── develop        # 개발 브랜치 (대기 중)
└── milkyway-dev/       # 🛠️ 개발 레포지토리 (새로 생성)
    ├── main           # 개발 메인 브랜치 (활성)
    └── feature/*       # 기능별 브랜치
```

## 🔄 **개발 워크플로우**

### 1️⃣ **개발 단계 (milkyway-dev)**
```bash
# 1. 개발용 레포지토리 클론
git clone https://github.com/unknownstarter/milkyway-dev.git
cd milkyway-dev

# 2. 기능별 브랜치 생성
git checkout -b feature/new-feature

# 3. 개발 작업 진행
# ... 코드 작성 ...

# 4. 커밋 및 푸시
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin feature/new-feature

# 5. Pull Request 생성
# GitHub에서 PR 생성 후 리뷰
```

### 2️⃣ **완성 후 병합 (milkyway)**
```bash
# 1. 프로덕션 레포지토리 클론
git clone https://github.com/unknownstarter/milkyway.git
cd milkyway

# 2. 개발 레포지토리에서 코드 가져오기
git remote add dev-repo https://github.com/unknownstarter/milkyway-dev.git
git fetch dev-repo

# 3. 병합
git merge dev-repo/main

# 4. 푸시
git push origin main
```

## 📋 **레포지토리별 용도**

| 레포지토리 | 용도 | 상태 | 작업 내용 | 접근 권한 |
|------------|------|------|-----------|-----------|
| **milkyway** | 프로덕션 | 대기 | 완성된 코드 병합 대기 | 제한적 |
| **milkyway-dev** | 개발 | 활성 | 모든 개발 작업 진행 | 자유적 |

## ⚠️ **중요 주의사항**

### 🚫 **절대 금지사항**
- **`milkyway` 레포지토리에서 직접 개발 금지**
- **`milkyway` 레포지토리의 main 브랜치 직접 수정 금지**
- **검증되지 않은 코드를 프로덕션에 배포 금지**

### ✅ **필수 준수사항**
- **모든 개발 작업은 `milkyway-dev`에서만 진행**
- **완성 후에만 `milkyway`로 병합**
- **병합 전 반드시 테스트 완료**
- **문서화 업데이트 필수**

## 🔧 **브랜치 전략**

### **milkyway-dev (개발 레포지토리)**
```
main                    # 개발 메인 브랜치
├── feature/auth        # 인증 기능
├── feature/books       # 책 관리 기능
├── feature/memos        # 메모 관리 기능
├── feature/home         # 홈 화면 기능
└── hotfix/*            # 긴급 수정
```

### **milkyway (프로덕션 레포지토리)**
```
main                    # 프로덕션 메인 브랜치
├── develop             # 개발 브랜치 (대기)
└── release/*           # 릴리스 브랜치
```

## 🚀 **배포 프로세스**

### 1️⃣ **개발 완료**
```bash
# milkyway-dev에서
git checkout main
git pull origin main
# 최종 테스트 완료
```

### 2️⃣ **프로덕션 병합**
```bash
# milkyway에서
git checkout main
git merge dev-repo/main
git push origin main
```

### 3️⃣ **배포 확인**
- 앱 스토어 배포
- 사용자 피드백 수집
- 버그 리포트 확인

## 📊 **작업 현황 추적**

### **현재 상태 (2024-12-19)**
- ✅ **milkyway-dev 레포지토리 생성 완료**
- ✅ **리팩토링된 코드 푸시 완료**
- ✅ **포괄적인 문서화 완료**
- ✅ **아키텍처 개선 완료**

### **다음 작업 계획**
- 🔄 **기능 개발** - milkyway-dev에서 진행
- 🔄 **테스트 작성** - 단위 테스트, 위젯 테스트
- 🔄 **성능 최적화** - 이미지 캐싱, 리스트 가상화
- 🔄 **문서 업데이트** - API 문서, 사용자 가이드

## 🆘 **문제 해결**

### **자주 발생하는 문제**
1. **잘못된 레포지토리에서 작업**
   ```bash
   # 해결: 올바른 레포지토리 확인
   git remote -v
   # milkyway-dev인지 확인
   ```

2. **브랜치 충돌**
   ```bash
   # 해결: 최신 코드로 업데이트
   git pull origin main
   git rebase origin/main
   ```

3. **의존성 문제**
   ```bash
   # 해결: 의존성 재설치
   flutter clean
   flutter pub get
   ```

## 📞 **연락처**

**프로젝트 매니저:** AI Assistant  
**개발팀:** Flutter Team  
**문서 작성일:** 2024-12-19  
**다음 업데이트:** 2024-12-20

---

**⚠️ 이 문서는 레포지토리 관리의 핵심 가이드입니다. 반드시 숙지하고 준수하세요!**
