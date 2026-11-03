import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/app_user.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../auth/view_models/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.auth,
    required this.onSignIn,
    required this.onOpenMap,
    required this.dockClearance,
  });

  final AuthController auth;
  final Future<bool> Function() onSignIn;
  final VoidCallback onOpenMap;
  final double dockClearance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 18, 20, dockClearance + 16),
            children: [
              const BrandLockup(compact: true),
              const SizedBox(height: 32),
              Text(
                'Tu cuenta.',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                auth.isSignedIn
                    ? 'Tus reportes y tu acceso a Tízibaches.'
                    : 'El mapa es abierto. La cuenta guarda tu historial.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              if (auth.isSignedIn)
                _SignedInCard(user: auth.session!.user)
              else
                _GuestCard(onSignIn: onSignIn, onOpenMap: onOpenMap),
              const SizedBox(height: 20),
              _MenuGroup(
                children: [
                  _MenuTile(
                    icon: LucideIcons.map,
                    label: 'Abrir el mapa',
                    detail: 'Expedientes públicos de Tizimín',
                    onTap: onOpenMap,
                  ),
                  if (auth.isSignedIn)
                    _MenuTile(
                      icon: LucideIcons.externalLink,
                      label: 'Mapa abierto en la web',
                      detail: 'Versión de escritorio',
                      onTap: () => _openWeb(context),
                    ),
                  _MenuTile(
                    icon: LucideIcons.info,
                    label: 'Acerca de Tízibaches',
                    detail: 'Versión 1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
              if (auth.isSignedIn) ...[
                const SizedBox(height: 20),
                _MenuGroup(
                  children: [
                    _MenuTile(
                      icon: LucideIcons.logOut,
                      label: 'Cerrar sesión',
                      detail: 'Se borran los tokens de este teléfono',
                      danger: true,
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openWeb(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppConfig.publicWebUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el navegador.')),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Los tokens se borran de este teléfono. Puedes volver a entrar con Google cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.clayDeep),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  Future<void> _showAbout(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.label,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
            const BrandLogo(size: 72),
            const SizedBox(height: 18),
            Text(
              'Tízibaches',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            Text(
              'Plataforma ciudadana para reportar baches y seguir su reparación. App para Android, datos abiertos en la web.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Desarrollado por Reynaldo Manzanilla.',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Versión 1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  'Tizimín, Yucatán',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.onDarkLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(user: user),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.label,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.onDarkLine),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 16,
                color: AppColors.maize,
              ),
              const SizedBox(width: 7),
              Text(
                user.isStaff ? 'Cuenta administradora' : 'Cuenta ciudadana',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.label,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const BrandLogo(size: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.maize,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.label.withValues(alpha: 0.22)),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onSignIn, required this.onOpenMap});

  final Future<bool> Function() onSignIn;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bag,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(size: 42),
          const SizedBox(height: 16),
          Text(
            'Explorás sin cuenta.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.label),
          ),
          const SizedBox(height: 6),
          Text(
            'Entrá con Google para reportar, guardar tu historial y recibir el estado de tus expedientes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSignIn,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.google, size: 18),
                  SizedBox(width: 9),
                  Text('Entrar con Google'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onOpenMap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.label,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Seguir en el mapa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const Divider(),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: danger ? AppColors.clayDeep : AppColors.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      color: danger ? AppColors.clayDeep : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
