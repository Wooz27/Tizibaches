import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import 'brand_logo.dart';

class PotholeLoader extends StatefulWidget {
  const PotholeLoader({super.key, this.label = 'Cargando expedientes'});

  final String label;

  @override
  State<PotholeLoader> createState() => _PotholeLoaderState();
}

class _PotholeLoaderState extends State<PotholeLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in [0.0, 0.33, 0.66])
                    Opacity(
                      opacity: (1 - ((_controller.value + offset) % 1)) * 0.35,
                      child: Transform.scale(
                        scale: 0.45 + ((_controller.value + offset) % 1) * 0.55,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.ink),
                          ),
                        ),
                      ),
                    ),
                  const BrandLogo(size: 30),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDark = false,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.label : AppColors.ink;
    final muted = onDark ? AppColors.onDarkMuted : AppColors.inkSoft;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(size: 42),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowUpRight, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({
    super.key,
    required this.message,
    this.onRetry,
    this.onDark = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.label.withValues(alpha: 0.08)
            : AppColors.paper,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: onDark ? AppColors.onDarkLine : AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 19,
            color: onDark ? AppColors.maize : AppColors.clayDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onDark ? AppColors.label : AppColors.ink,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: onDark ? AppColors.maize : AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
