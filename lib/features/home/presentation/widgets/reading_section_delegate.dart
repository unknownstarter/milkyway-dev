import 'package:flutter/material.dart';

/// Reading 섹션을 위한 SliverPersistentHeaderDelegate
/// 
/// 스크롤 시 확장된 형태(큰 책 표지)에서 축소된 형태(작은 카드)로 전환
class ReadingSectionDelegate extends SliverPersistentHeaderDelegate {
  final Widget expandedChild;
  final Widget collapsedChild;
  final double maxHeight;
  final double minHeight;

  // 오버플로우 방지를 위한 전환 threshold 상수
  static const double _transitionThreshold = 0.01; // 1% 진행 시 즉시 전환
  static const double _gestureIgnoreOffset = 0.1; // 전환 직후 제스처 무시 오프셋
  static const double _expandedDisplayThreshold = 0.001; // expandedChild 표시 조건 (거의 0일 때만)

  // Figma 디자인 상수
  static const double collapsedCardHeight =
      108.0; // Figma: Frame 31 높이 (작은 카드 형태)

  ReadingSectionDelegate({
    required this.expandedChild,
    required this.collapsedChild,
    required double height,
  })  : maxHeight = height,
        minHeight = collapsedCardHeight;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // shrinkOffset에 따른 진행도 계산 (0.0 = 완전히 펼쳐짐, 1.0 = 완전히 축소됨)
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);

    // 현재 높이 계산 (정확히 제한) - minHeight 이하로 내려가지 않도록
    final currentHeight =
        (maxHeight - shrinkOffset).clamp(minHeight, maxHeight);

    // 오버플로우 방지를 위한 즉시 전환 threshold
    // progress가 threshold 이상이면 (즉, 스크롤이 시작되면 거의 즉시)
    // expandedChild를 즉시 숨기고 collapsedChild를 표시
    // 이렇게 하면 오버플로우가 발생할 수 있는 구간을 완전히 피할 수 있음
    // expandedChild는 progress < 0.001일 때만 표시 (거의 0일 때만)
    final shouldShowExpanded = progress < _expandedDisplayThreshold;
    final shouldShowCollapsed = progress >= _transitionThreshold;

    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Container(
        color: const Color(0xFF181818),
        height: currentHeight, // 현재 높이로 정확히 제한 (외부 컨테이너)
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge, // 오버플로우 강제 차단
          children: [
            // 확장된 형태 (큰 책 표지) - progress < 0.001일 때만 표시 (거의 0일 때만)
            // 스크롤이 시작되면 즉시 collapsed로 전환하여 오버플로우 완전 방지
            if (shouldShowExpanded)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Opacity(
                    opacity: 1.0,
                    child: SizedBox(
                      height: maxHeight, // maxHeight로 완전히 제한 (currentHeight 대신 maxHeight 사용)
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ClipRect(
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            height: maxHeight, // 이중 제한으로 오버플로우 완전 방지
                            child: expandedChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // 축소된 형태 (작은 카드) - threshold 이후 즉시 표시
            if (shouldShowCollapsed)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: progress <
                      _transitionThreshold +
                          _gestureIgnoreOffset, // 전환 직후 잠시 제스처 무시
                  child: Opacity(
                    opacity: shouldShowExpanded
                        ? 0.0 // expanded가 보이는 동안은 투명
                        : 1.0, // expanded가 사라지면 즉시 표시
                    child: ClipRect(
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        height: minHeight, // 항상 정확히 minHeight로 고정
                        width: double.infinity,
                        child: collapsedChild,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(ReadingSectionDelegate oldDelegate) {
    return expandedChild != oldDelegate.expandedChild ||
        collapsedChild != oldDelegate.collapsedChild ||
        maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}

