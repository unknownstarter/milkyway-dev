import 'package:flutter/material.dart';

/// 메모 공개/비공개 토글 위젯
class MemoVisibilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MemoVisibilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '메모 공개 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 28 / 20,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '이 스위치를 켜면 메모가 공개돼요',
              style: TextStyle(
                color: Color(0xFF838383),
                fontSize: 16,
                fontFamily: 'Pretendard',
                height: 22.4 / 16,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF48FF00),
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF2C2C2C),
            ),
          ],
        ),
      ],
    );
  }
}

