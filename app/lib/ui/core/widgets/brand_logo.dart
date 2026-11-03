import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.size,
    this.full = false,
    this.borderRadius = 2,
  });

  final double size;
  final bool full;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final pixels = (size * ratio).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        full ? 'assets/branding/logo.webp' : 'assets/branding/logo-mark.webp',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: pixels,
        cacheHeight: pixels,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
