import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/brand_logo.dart';
import '../view_models/auth_controller.dart';

class AuthPromptSheet extends StatelessWidget {
  const AuthPromptSheet({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.label,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 22),
              const BrandLogo(size: 42),
              const SizedBox(height: 18),
              Text(
                'Para reportar,\nentrá con Google.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tu cuenta identifica el reporte y te deja seguir su estado. El mapa sigue abierto para todos.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                InlineError(message: auth.error!),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.busy
                      ? null
                      : () async {
                          final success = await auth.signIn();
                          if (success && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                  child: auth.busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ink,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.google, size: 18),
                            SizedBox(width: 9),
                            Text('Entrar con Google'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: auth.busy
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Seguir explorando'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
