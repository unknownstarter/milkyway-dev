import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/models/memo.dart';
import '../../../../core/router/app_routes.dart';

/// 책 상세 화면과 메모 리스트 화면에서 사용하는 메모 카드 컴포넌트
/// 
/// 이미지 유무를 자동으로 감지하여 적절한 레이아웃으로 표시
class BookDetailMemoCard extends StatelessWidget {
  final Memo memo;
  final double cardWidth;

  const BookDetailMemoCard({
    super.key,
    required this.memo,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = memo.imageUrl != null && memo.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.pushNamed(
            AppRoutes.memoDetailName,
            pathParameters: {'id': memo.id},
          ),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(bottom: 40),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasImage
            ? _buildMemoCardWithImage(context, memo)
            : _buildMemoCardTextOnly(context, memo),
      ),
    );
  }

  /// 텍스트만 있는 메모 카드
  Widget _buildMemoCardTextOnly(BuildContext context, Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // 피그마: 메모 카드에 padding 없음
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          _buildUserInfo(memo),
          const SizedBox(height: 16),
          // 메모 내용
          Text(
            memo.content,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 16),
          // 책 제목 및 페이지
          _buildBookInfo(context, memo),
        ],
      ),
    );
  }

  /// 이미지가 있는 메모 카드
  Widget _buildMemoCardWithImage(BuildContext context, Memo memo) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero, // 피그마: 메모 카드에 padding 없음
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          _buildUserInfo(memo),
          const SizedBox(height: 16),
          // 메모 내용 및 이미지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  memo.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15),
              // 이미지 (80x120)
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade900,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    memo.imageUrl!,
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade900,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 책 제목 및 페이지
          _buildBookInfo(context, memo),
        ],
      ),
    );
  }

  /// 사용자 정보 위젯 (아바타, 닉네임, 시간)
  Widget _buildUserInfo(Memo memo) {
    return Row(
      children: [
        // 아바타
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade800,
          ),
          child: ClipOval(
            child: memo.userAvatarUrl != null &&
                    memo.userAvatarUrl!.isNotEmpty
                ? Image.network(
                    memo.userAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.grey),
                  )
                : const Icon(Icons.person, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 12),
        // 닉네임 및 시간
        Expanded(
          child: Row(
            children: [
              Text(
                memo.userNickname ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(memo.createdAt, locale: 'ko'),
                style: const TextStyle(
                  color: Color(0xFF838383),
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w300,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 책 제목 및 페이지 정보 위젯
  Widget _buildBookInfo(BuildContext context, Memo memo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: Text(
              memo.bookTitle,
              style: const TextStyle(
                color: Color(0xFF838383),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w300,
                fontSize: 16,
                height: 24 / 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (memo.page != null)
          Text(
            'p ${memo.page}',
            style: const TextStyle(
              color: Color(0xFF838383),
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w300,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
      ],
    );
  }
}

