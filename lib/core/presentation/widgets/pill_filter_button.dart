import 'package:flutter/material.dart';

/// 알약 형태의 필터 버튼 위젯
/// 
/// 재사용 가능한 필터 버튼 컴포넌트
/// BookShelfScreen, BookDetailScreen 등에서 공통으로 사용
class PillFilterButton extends StatelessWidget {
  /// 버튼에 표시할 텍스트
  final String label;
  
  /// 활성화 상태 여부
  final bool isActive;
  
  /// 버튼 클릭 시 호출되는 콜백
  final VoidCallback onTap;
  
  /// 버튼 너비
  final double width;
  
  /// 폰트 크기 (기본값: 12)
  final double fontSize;
  
  /// 활성화 시 폰트 굵기 (기본값: w700)
  final FontWeight activeFontWeight;
  
  /// 비활성화 시 폰트 굵기 (기본값: w400)
  final FontWeight inactiveFontWeight;

  const PillFilterButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.width,
    this.fontSize = 12,
    this.activeFontWeight = FontWeight.w700,
    this.inactiveFontWeight = FontWeight.w400,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3C3C3C) : const Color(0xFF212121),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF6A6A6A),
                fontFamily: 'Pretendard',
                fontWeight: isActive ? activeFontWeight : inactiveFontWeight,
                fontSize: fontSize,
                height: 18 / fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

