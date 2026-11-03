import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/pothole_status.dart';
import '../status_style.dart';

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status, this.size = 8});

  final PotholeStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.label.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.onDark = false,
    this.compact = false,
  });

  final PotholeStatus status;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = onDark
        ? AppColors.label.withValues(alpha: 0.1)
        : status.color.withValues(alpha: 0.12);
    final foreground = onDark ? AppColors.label : AppColors.ink;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: onDark
              ? AppColors.onDarkLine
              : status.color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.shortLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.status,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PotholeStatus? status;

  @override
  Widget build(BuildContext context) {
    final selectedColor = status?.color ?? AppColors.ink;
    final foreground = selected
        ? (status?.onColor ?? AppColors.label)
        : AppColors.inkSoft;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor
                : AppColors.label.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: selected ? selectedColor : AppColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: selected
                        ? foreground.withValues(alpha: 0.8)
                        : status!.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeverityBars extends StatelessWidget {
  const SeverityBars({
    super.key,
    required this.severity,
    this.onDark = false,
    this.showLabel = false,
  });

  final int severity;
  final bool onDark;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final active = onDark ? AppColors.maize : AppColors.ink;
    final inactive = onDark ? AppColors.onDarkLine : AppColors.line;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 4; i++)
          Container(
            width: 13,
            height: 5,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i <= severity ? active : inactive,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Text(
            switch (severity) {
              <= 1 => 'Leve',
              2 => 'Moderado',
              3 => 'Grave',
              _ => 'Muy grave',
            },
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onDark ? AppColors.label : AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
