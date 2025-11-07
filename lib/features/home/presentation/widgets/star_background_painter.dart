import 'dart:math';
import 'package:flutter/material.dart';

class StarBackgroundPainter extends CustomPainter {
  final int numberOfStars;

  StarBackgroundPainter({this.numberOfStars = 100});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()
      ..color = Colors.white.withAlpha(77)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < numberOfStars; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2 + 1; // 1-3px 크기의 별

      // 랜덤하게 별의 투명도 조절
      paint.color = Colors.white.withAlpha(((random.nextDouble() * 0.3 + 0.1) * 255).toInt());

      canvas.drawCircle(Offset(x, y), starSize / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
