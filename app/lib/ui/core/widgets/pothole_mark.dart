import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'brand_logo.dart';

class PotholeMark extends StatelessWidget {
  const PotholeMark({
    super.key,
    this.size = 40,
    this.color = AppColors.ink,
    this.holeColor = AppColors.label,
  });

  final double size;
  final Color color;
  final Color holeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PotholeMarkPainter(color: color, holeColor: holeColor),
      ),
    );
  }
}

class _PotholeMarkPainter extends CustomPainter {
  const _PotholeMarkPainter({required this.color, required this.holeColor});

  final Color color;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.save();
    canvas.scale(scale);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.55);
    canvas.drawRect(const Rect.fromLTWH(0.5, 0.5, 39, 39), border);

    final solid = Paint()..color = color;
    final blob = Path()
      ..moveTo(20, 6.5)
      ..cubicTo(27.2, 6.5, 32.6, 11.8, 32.6, 18.7)
      ..cubicTo(32.6, 25.9, 27, 33.5, 20, 33.5)
      ..cubicTo(13, 33.5, 7.4, 25.9, 7.4, 18.7)
      ..cubicTo(7.4, 11.8, 12.8, 6.5, 20, 6.5)
      ..close();
    canvas.drawPath(blob, solid);

    final hole = Paint()..color = holeColor;
    final inner = Path()
      ..moveTo(14, 15.5)
      ..cubicTo(16, 12.8, 19.7, 12.9, 21.6, 15.6)
      ..cubicTo(23.4, 18.2, 22.6, 21.6, 20.3, 23.2)
      ..cubicTo(17.9, 24.8, 14.7, 23.9, 13.3, 21.4)
      ..cubicTo(12, 19.1, 12.4, 16.8, 14, 15.5)
      ..close();
    canvas.drawPath(inner, hole);

    final center = Paint()..color = color;
    canvas.drawCircle(const Offset(18, 18.8), 1.8, center);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PotholeMarkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.holeColor != holeColor;
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.onDark = false,
    this.compact = false,
    this.subtitle = 'Tizimín, Yucatán',
  });

  final bool onDark;
  final bool compact;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? AppColors.label : AppColors.ink;
    final subColor = onDark
        ? AppColors.label.withValues(alpha: 0.62)
        : AppColors.inkSoft;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(size: compact ? 34 : 40),
        const SizedBox(width: 11),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tízibaches',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontSize: compact ? 18 : 21,
                letterSpacing: -0.7,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: subColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
