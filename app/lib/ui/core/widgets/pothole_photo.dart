import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'brand_logo.dart';

class PotholePhoto extends StatelessWidget {
  const PotholePhoto({
    super.key,
    required this.photoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.darkPlaceholder = false,
  });

  final String? photoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool darkPlaceholder;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url == null || url.isEmpty) {
      return _Placeholder(width: width, height: height, dark: darkPlaceholder);
    }

    if (url.startsWith('asset://')) {
      return Image.asset(
        url.substring('asset://'.length),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) =>
            _Placeholder(width: width, height: height, dark: darkPlaceholder),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          _Placeholder(width: width, height: height, dark: darkPlaceholder),
      errorWidget: (context, url, error) =>
          _Placeholder(width: width, height: height, dark: darkPlaceholder),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height, required this.dark});

  final double? width;
  final double? height;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: dark ? AppColors.gusset : AppColors.paperDeep,
      alignment: Alignment.center,
      child: const BrandLogo(size: 34),
    );
  }
}
