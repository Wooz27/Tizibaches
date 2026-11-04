import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/pothole.dart';
import '../../../../domain/models/pothole_status.dart';
import '../../../core/widgets/photo_viewer_screen.dart';
import '../../../core/widgets/pothole_photo.dart';
import '../../../core/widgets/status_widgets.dart';

class PotholeDetailSheet extends StatelessWidget {
  const PotholeDetailSheet({super.key, required this.pothole});

  final Pothole pothole;

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${pothole.latitude},${pothole.longitude}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la aplicación de mapas.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final lastReport = pothole.lastReportedAt;
    final fixed = pothole.fixedAt;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.label,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium!.copyWith(color: AppColors.ink),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 22 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 9),
              Center(
                child: Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: pothole.photoUrl == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PhotoViewerScreen(
                                photoUrl: pothole.photoUrl!,
                                title: pothole.displayName,
                              ),
                            ),
                          ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: SizedBox(
                        height: 222,
                        width: double.infinity,
                        child: PotholePhoto(
                          photoUrl: pothole.photoUrl,
                          darkPlaceholder: true,
                        ),
                      ),
                    ),
                  ),
                  if (pothole.photoUrl != null)
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          color: AppColors.ink.withValues(alpha: 0.72),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.maximize2,
                                size: 13,
                                color: AppColors.label,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Ampliar',
                                style: TextStyle(
                                  color: AppColors.label,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 14,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        color: AppColors.label,
                        child: StatusBadge(status: pothole.status),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Material(
                      color: AppColors.label,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pothole.name.trim().isNotEmpty) ...[
                      Text(
                        pothole.name.trim(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pothole.displayAddress,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.inkSoft),
                      ),
                    ] else
                      Text(
                        pothole.displayAddress,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        SeverityBars(
                          severity: pothole.severity,
                          showLabel: true,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bache #${pothole.id}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Reportes ciudadanos',
                            value:
                                '${pothole.reportCount} ${pothole.reportCount == 1 ? 'reporte' : 'reportes'}',
                          ),
                          if (lastReport != null) ...[
                            const SizedBox(height: 11),
                            _DetailRow(
                              label: 'Último reporte',
                              value: DateFormat(
                                "d 'de' MMMM 'de' y",
                                'es_MX',
                              ).format(lastReport),
                            ),
                          ],
                          if (fixed != null) ...[
                            const SizedBox(height: 11),
                            _DetailRow(
                              label: 'Reparado',
                              value: DateFormat(
                                "d 'de' MMMM 'de' y",
                                'es_MX',
                              ).format(fixed),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (pothole.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTA DEL REPORTANTE',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.muted,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pothole.note.trim(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      pothole.status == PotholeStatus.fixed
                          ? 'Este expediente ya está cerrado. El historial queda visible para consulta.'
                          : 'El estado se actualiza desde el panel de administración. El expediente sigue abierto para nuevos reportes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openMaps(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.navigation, size: 18),
                            SizedBox(width: 9),
                            Text('Cómo llegar'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
