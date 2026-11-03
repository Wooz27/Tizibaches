import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../../core/widgets/topographic_background.dart';
import '../view_models/auth_controller.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bag,
        body: Stack(
          children: [
            const Positioned.fill(
              child: TopographicBackground(color: AppColors.label),
            ),
            Positioned(
              left: -120,
              top: -140,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.maize.withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36,
                      ),
                      child: AnimatedBuilder(
                        animation: widget.auth,
                        builder: (context, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: BrandLockup(onDark: true),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.onDarkLine,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.android,
                                          size: 14,
                                          color: AppColors.label,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Android',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColors.label,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 72),
                              Text(
                                'Cada bache,\nun expediente.',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: AppColors.label,
                                      fontSize: 47,
                                      letterSpacing: -2.4,
                                      height: 0.93,
                                    ),
                              ),
                              const SizedBox(height: 22),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
                                child: Text(
                                  'Una foto y tu ubicación bastan. El expediente queda abierto para todos.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.label.withValues(
                                          alpha: 0.7,
                                        ),
                                        height: 1.5,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 34),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: AppColors.onDarkLine,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _Promise(
                                      icon: LucideIcons.camera,
                                      label: 'Foto',
                                    ),
                                    _Promise(
                                      icon: LucideIcons.crosshair,
                                      label: 'GPS',
                                    ),
                                    _Promise(
                                      icon: LucideIcons.badgeCheck,
                                      label: 'Seguimiento',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 34),
                              if (widget.auth.error != null) ...[
                                const SizedBox(height: 22),
                                InlineError(
                                  message: widget.auth.error!,
                                  onDark: true,
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: widget.auth.busy
                                      ? null
                                      : widget.auth.signIn,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 54),
                                  ),
                                  child: widget.auth.busy
                                      ? const SizedBox.square(
                                          dimension: 19,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.ink,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.google,
                                              size: 19,
                                            ),
                                            const SizedBox(width: 10),
                                            const Text('Entrar con Google'),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: widget.auth.busy
                                      ? null
                                      : widget.auth.continueAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.label,
                                    side: const BorderSide(
                                      color: AppColors.onDarkLine,
                                    ),
                                    minimumSize: const Size(0, 50),
                                  ),
                                  child: const Text('Explorar el mapa'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.android,
                                    size: 13,
                                    color: AppColors.onDarkMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Solo Android  ·  Tizimín, Yucatán',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.onDarkMuted,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.maize),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.label.withValues(alpha: 0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
