import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TopographicBackground extends StatelessWidget {
  const TopographicBackground({super.key, this.color = AppColors.label});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TopographicPainter(color),
        size: Size.infinite,
      ),
    );
  }
}

class _TopographicPainter extends CustomPainter {
  _TopographicPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.11);

    for (var line = 0; line < 8; line++) {
      final path = Path();
      final base = size.height * (0.14 + line * 0.105);
      for (var x = -10.0; x <= size.width + 10; x += 12) {
        final y =
            base +
            math.sin((x / size.width) * math.pi * 2.2 + line * 0.7) *
                (18 + line * 3) +
            math.sin((x / size.width) * math.pi * 5.1 + line) * 8;
        if (x <= 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = color.withValues(alpha: 0.05);
    for (var x = 0.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(_TopographicPainter oldDelegate) =>
      oldDelegate.color != color;
}
