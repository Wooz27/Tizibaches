import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

class AppDock extends StatelessWidget {
  const AppDock({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onReport,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.onDarkLine),
        ),
        child: Row(
          children: [
            _DockTab(
              label: 'Mapa',
              icon: LucideIcons.map,
              selected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _ReportTab(onTap: onReport),
            _DockTab(
              label: 'Reportes',
              icon: LucideIcons.list,
              selected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _DockTab(
              label: 'Perfil',
              icon: LucideIcons.circleUserRound,
              selected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? AppColors.maize
                    : AppColors.label.withValues(alpha: 0.62),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? AppColors.maize
                      : AppColors.label.withValues(alpha: 0.62),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Reportar un bache',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.maize,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.camera,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reportar',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.label,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
