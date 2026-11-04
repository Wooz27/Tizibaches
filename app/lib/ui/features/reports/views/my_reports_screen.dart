import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/report.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../../core/widgets/pothole_photo.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../auth/view_models/auth_controller.dart';
import '../view_models/my_reports_view_model.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({
    super.key,
    required this.auth,
    required this.viewModel,
    required this.onReport,
    required this.onSignIn,
    required this.onOpenMap,
    required this.dockClearance,
  });

  final AuthController auth;
  final MyReportsViewModel viewModel;
  final VoidCallback onReport;
  final Future<bool> Function() onSignIn;
  final ValueChanged<int> onOpenMap;
  final double dockClearance;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_handleAuth);
    if (widget.auth.isSignedIn) widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_handleAuth);
    super.dispose();
  }

  void _handleAuth() {
    if (widget.auth.isSignedIn) {
      widget.viewModel.load();
    } else {
      widget.viewModel.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.auth, widget.viewModel]),
        builder: (context, _) {
          final signedIn = widget.auth.isSignedIn;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverList.list(
                  children: [
                    const BrandLockup(compact: true),
                    const SizedBox(height: 32),
                    Text(
                      'Tus reportes.',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      signedIn
                          ? 'Sigue el estado de cada bache que reportaste.'
                          : 'Entra con Google para guardar y seguir tus reportes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (!signedIn)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _GuestPanel(onSignIn: widget.onSignIn),
                  ),
                )
              else if (widget.viewModel.loading &&
                  widget.viewModel.reports.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 44),
                    child: Center(child: PotholeLoader()),
                  ),
                )
              else if (widget.viewModel.error != null &&
                  widget.viewModel.reports.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: InlineError(
                      message: widget.viewModel.error!,
                      onRetry: widget.viewModel.load,
                    ),
                  ),
                )
              else if (widget.viewModel.reports.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'Todavía no reportaste nada.',
                    message:
                        'Cuando veas un bache, toma una foto y marca el punto. Tu reporte queda en tu historial y en el mapa público.',
                    actionLabel: 'Reportar un bache',
                    onAction: widget.onReport,
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Text(
                          '${widget.viewModel.reports.length} ${widget.viewModel.reports.length == 1 ? 'reporte' : 'reportes'}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.inkSoft),
                        ),
                        const Spacer(),
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 15,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Solo visible para ti',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    widget.dockClearance + 16,
                  ),
                  sliver: SliverList.separated(
                    itemCount: widget.viewModel.reports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final report = widget.viewModel.reports[index];
                      return _MyReportCard(
                        report: report,
                        onOpenMap: () => widget.onOpenMap(report.potholeId),
                      );
                    },
                  ),
                ),
              ],
              if (signedIn && widget.viewModel.reports.isEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }
}

class _GuestPanel extends StatelessWidget {
  const _GuestPanel({required this.onSignIn});

  final Future<bool> Function() onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bag,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                color: AppColors.maize,
                child: const Icon(
                  LucideIcons.circleUserRound,
                  size: 19,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Mapa abierto,\nhistorial con cuenta.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.label,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Puedes explorar todos los baches sin cuenta. Para reportar y seguir tus envíos, entra con Google.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({required this.report, required this.onOpenMap});

  final Report report;
  final VoidCallback onOpenMap;

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
          Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: PotholePhoto(
                    photoUrl: report.photoUrl,
                    width: 74,
                    height: 74,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusDot(status: report.status, size: 7),
                          const SizedBox(width: 6),
                          Text(
                            report.status.label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'd MMM y',
                              'es_MX',
                            ).format(report.createdAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        report.description.trim().isEmpty
                            ? 'Reporte sin nota.'
                            : report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SeverityBars(severity: report.severity),
                          const SizedBox(width: 8),
                          Text(
                            report.severityLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.inkSoft),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onOpenMap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Ver mapa'),
                                SizedBox(width: 4),
                                Icon(LucideIcons.arrowRight, size: 13),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Text(
                  'Bache #${report.potholeId}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  'Reporte #${report.id}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
