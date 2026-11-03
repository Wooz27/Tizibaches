import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/pothole.dart';
import '../../../core/widgets/pothole_photo.dart';
import '../../../core/widgets/status_widgets.dart';

class PotholeListCard extends StatelessWidget {
  const PotholeListCard({
    super.key,
    required this.pothole,
    required this.onTap,
  });

  final Pothole pothole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = pothole.lastReportedAt;
    return Semantics(
      button: true,
      label: 'Abrir expediente de ${pothole.displayAddress}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(2),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: PotholePhoto(
                        photoUrl: pothole.photoUrl,
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pothole.displayAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontSize: 14, height: 1.2),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            StatusDot(status: pothole.status, size: 7),
                            const SizedBox(width: 6),
                            Text(
                              pothole.status.label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${pothole.reportCount} ${pothole.reportCount == 1 ? 'reporte' : 'reportes'}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            if (date != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('d MMM', 'es_MX').format(date),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Abrir ficha',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.arrowRight,
                              size: 12,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 15,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
