import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/report.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../../core/widgets/topographic_background.dart';

class ReportSuccessScreen extends StatefulWidget {
  const ReportSuccessScreen({super.key, required this.result});

  final ReportSubmission result;

  @override
  State<ReportSuccessScreen> createState() => _ReportSuccessScreenState();
}

class _ReportSuccessScreenState extends State<ReportSuccessScreen> {
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

  ReportSubmission get result => widget.result;

  String get _distance {
    final distance = result.distanceMeters;
    if (distance == null) return '';
    if (distance < 1) return 'a menos de 1 metro';
    return 'a ${distance.round()} metros';
  }

  @override
  Widget build(BuildContext context) {
    final created = result.created;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bag,
        body: Stack(
          children: [
            const Positioned.fill(
              child: TopographicBackground(color: AppColors.label),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLockup(onDark: true),
                    const Spacer(),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.maize,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 36,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      created ? 'Expediente\ncreado.' : 'Reporte\nsumado.',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.label,
                        fontSize: 46,
                        height: 0.93,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        created
                            ? 'Tu foto abrió un expediente nuevo. Ahora puedes seguir su estado desde el mapa.'
                            : 'Ya existía un expediente $_distance. Tu reporte se sumó y refuerza el aviso.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.label.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.onDarkLine),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Bache #${result.report.potholeId}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 14,
                            color: AppColors.onDarkLine,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            result.report.status.label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.maize,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.map, size: 18),
                            SizedBox(width: 9),
                            Text('Ver en el mapa'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
