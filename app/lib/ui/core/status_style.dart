import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/pothole_status.dart';

extension PotholeStatusStyle on PotholeStatus {
  Color get color => switch (this) {
    PotholeStatus.pending => AppColors.muted,
    PotholeStatus.reported => AppColors.clay,
    PotholeStatus.verified => AppColors.sky,
    PotholeStatus.scheduled => AppColors.gusset,
    PotholeStatus.inProgress => AppColors.clayDeep,
    PotholeStatus.fixed => AppColors.sage,
    PotholeStatus.rejected => AppColors.muted,
    PotholeStatus.unknown => AppColors.muted,
  };

  Color get onColor => switch (this) {
    PotholeStatus.pending => AppColors.label,
    PotholeStatus.verified => AppColors.ink,
    PotholeStatus.rejected => AppColors.label,
    PotholeStatus.unknown => AppColors.label,
    _ => AppColors.label,
  };

  IconData get icon => switch (this) {
    PotholeStatus.pending => LucideIcons.clock,
    PotholeStatus.reported => LucideIcons.triangleAlert,
    PotholeStatus.verified => LucideIcons.badgeCheck,
    PotholeStatus.scheduled => LucideIcons.clock,
    PotholeStatus.inProgress => LucideIcons.hand,
    PotholeStatus.fixed => LucideIcons.circleCheck,
    PotholeStatus.rejected => LucideIcons.x,
    PotholeStatus.unknown => LucideIcons.info,
  };

  String get shortLabel => switch (this) {
    PotholeStatus.pending => 'Pendiente',
    PotholeStatus.reported => 'Reportado',
    PotholeStatus.verified => 'Verificado',
    PotholeStatus.scheduled => 'Programado',
    PotholeStatus.inProgress => 'En obra',
    PotholeStatus.fixed => 'Reparado',
    PotholeStatus.rejected => 'Rechazado',
    PotholeStatus.unknown => 'Sin estado',
  };
}

const List<PotholeStatus> mapStatusFilters = [
  PotholeStatus.pending,
  PotholeStatus.reported,
  PotholeStatus.inProgress,
  PotholeStatus.fixed,
];
