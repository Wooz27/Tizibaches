import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/topographic_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bag,
      body: Stack(
        children: [
          const Positioned.fill(
            child: TopographicBackground(color: AppColors.label),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 140, full: true),
                const SizedBox(height: 20),
                Text(
                  'Tizimín, Yucatán',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.label.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
