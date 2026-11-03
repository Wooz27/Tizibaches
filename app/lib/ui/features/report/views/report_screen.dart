import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/map_tiles.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../auth/view_models/auth_controller.dart';
import '../view_models/report_controller.dart';
import 'report_success_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.controller, required this.auth});

  final ReportController controller;
  final AuthController auth;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.recoverLostPhoto();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _retakePhoto() async {
    final controller = widget.controller;
    if (controller.location == null) {
      await controller.takePhoto();
      return;
    }

    final useGallery = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Cambiar la foto'),
        content: const Text(
          'Ya marcaste la ubicación. Si Android te dio permiso "Solo esta vez", volver a la cámara puede cerrar la app. Para evitarlo, elige la galería.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usar galería'),
          ),
        ],
      ),
    );
    if (useGallery == true) await controller.pickPhoto();
  }

  Future<void> _submit() async {
    final success = await widget.controller.submit();
    if (!success || !mounted) return;
    final result = widget.controller.result;
    if (result == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ReportSuccessScreen(result: result),
      ),
      result: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.label,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              return Column(
                children: [
                  _ReportTopBar(
                    onBack: () => Navigator.of(context).pop(),
                    userName: widget.auth.session?.user.displayName,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reporta un bache.',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Una foto, tu ubicación y una nota. Si ya existe un expediente cerca, tu reporte se suma en lugar de duplicarlo.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 22),
                          _PhotoBlock(
                            controller: controller,
                            onRetake: _retakePhoto,
                          ),
                          const SizedBox(height: 26),
                          _SectionTitle(
                            title: 'Ubicación',
                            detail: controller.location == null
                                ? 'Necesitamos el punto exacto.'
                                : controller.approximate
                                ? 'Usaste el centro de Tizimín.'
                                : 'Ubicación lista.',
                          ),
                          const SizedBox(height: 10),
                          _LocationBlock(
                            controller: controller,
                            onLocate: controller.photo == null
                                ? null
                                : controller.locate,
                          ),
                          const SizedBox(height: 26),
                          const _SectionTitle(
                            title: 'Severidad',
                            detail: '¿Qué tan grande es el bache?',
                          ),
                          const SizedBox(height: 10),
                          _SeveritySelector(
                            value: controller.severity,
                            onChanged: controller.setSeverity,
                          ),
                          const SizedBox(height: 26),
                          const _SectionTitle(
                            title: 'Detalle',
                            detail: 'Opcional, pero ayuda a clasificar el bache.',
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _description,
                            onChanged: controller.setDescription,
                            maxLines: 4,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              hintText:
                                  'Ej. Hueco profundo junto al paso peatonal.',
                              alignLabelWithHint: true,
                            ),
                            buildCounter:
                                (
                                  context, {
                                  required currentLength,
                                  required isFocused,
                                  required maxLength,
                                }) => null,
                          ),
                          if (controller.error != null) ...[
                            const SizedBox(height: 16),
                            InlineError(message: controller.error!),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: controller.canSubmit ? _submit : null,
                              child: controller.submitting
                                  ? const SizedBox.square(
                                      dimension: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.ink,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.send, size: 18),
                                        SizedBox(width: 9),
                                        Text('Enviar reporte'),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'El reporte es público. Si hay un bache a menos de 15 metros, se agrupa en el mismo expediente.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportTopBar extends StatelessWidget {
  const _ReportTopBar({required this.onBack, this.userName});

  final VoidCallback onBack;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
      child: Row(
        children: [
          Material(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(2),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(2),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  LucideIcons.arrowLeft,
                  size: 19,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const BrandLockup(compact: true),
          const Spacer(),
          Flexible(
            child: Text(
              userName == null || userName!.isEmpty
                  ? 'Reporte nuevo'
                  : 'Reportando como $userName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({required this.controller, required this.onRetake});

  final ReportController controller;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final photo = controller.photo;
    if (photo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.memory(
              photo.bytes,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onRetake,
                icon: const Icon(LucideIcons.camera, size: 16),
                label: const Text('Cambiar foto'),
              ),
              TextButton.icon(
                onPressed: controller.pickPhoto,
                icon: const Icon(LucideIcons.image, size: 16),
                label: const Text('Galería'),
              ),
              const Spacer(),
              IconButton(
                onPressed: controller.clearPhoto,
                tooltip: 'Quitar foto',
                icon: const Icon(
                  LucideIcons.trash,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.bag,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _ViewfinderPainter()),
          ),
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: controller.takePhoto,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.maize,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        size: 25,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Tomar foto',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.label),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'o elige una de la galería',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                Text(
                  'La foto es obligatoria',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onDarkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.pickPhoto,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.label,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Galería'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.label.withValues(alpha: 0.35);
    const inset = 18.0;
    const length = 22.0;
    final corners = [
      (Offset(inset, inset), const Offset(1, 1)),
      (Offset(size.width - inset, inset), const Offset(-1, 1)),
      (Offset(inset, size.height - inset), const Offset(1, -1)),
      (Offset(size.width - inset, size.height - inset), const Offset(-1, -1)),
    ];
    for (final (point, direction) in corners) {
      canvas.drawLine(point, point + Offset(direction.dx * length, 0), paint);
      canvas.drawLine(point, point + Offset(0, direction.dy * length), paint);
    }
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.controller, required this.onLocate});

  final ReportController controller;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final location = controller.location;
    if (location != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 142,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(location.latitude, location.longitude),
                  initialZoom: 16.2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  ...appTileLayers(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(location.latitude, location.longitude),
                        width: 34,
                        height: 34,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.maize,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                controller.approximate
                    ? LucideIcons.triangleAlert
                    : LucideIcons.mapPin,
                size: 16,
                color: controller.approximate
                    ? AppColors.clayDeep
                    : AppColors.sage,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  controller.approximate
                      ? 'Ubicación aproximada: centro de Tizimín'
                      : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: controller.approximate
                        ? AppColors.clayDeep
                        : AppColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(onPressed: onLocate, child: const Text('Actualizar')),
            ],
          ),
          if (kDebugMode)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.useCityCenter,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('Usar el centro para probar'),
              ),
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.crosshair, size: 24, color: AppColors.ink),
          const SizedBox(height: 12),
          Text(
            'Marca el punto del bache.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            onLocate == null
                ? 'Toma la foto primero. Así evitamos que Android cierre la app por el permiso de ubicación "solo esta vez" al abrir la cámara.'
                : 'La ubicación se guarda junto con la foto para que el bache quede ubicado en el mapa.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.locating ? null : onLocate,
              child: controller.locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.crosshair, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          onLocate == null
                              ? 'Primero toma la foto'
                              : 'Usar mi ubicación',
                        ),
                      ],
                    ),
            ),
          ),
          if (kDebugMode)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: controller.useCityCenter,
                child: const Text('Usar el centro para probar'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _labels = ['Leve', 'Moderado', 'Grave', 'Muy grave'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 1; index <= 4; index++) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: value == index,
              label: _labels[index - 1],
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 58,
                  decoration: BoxDecoration(
                    color: value == index ? AppColors.ink : AppColors.paper,
                    border: Border.all(
                      color: value == index ? AppColors.ink : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _labels[index - 1],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: value == index
                              ? AppColors.label
                              : AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SeverityBars(severity: index, onDark: value == index),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (index != 4) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            detail,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}
