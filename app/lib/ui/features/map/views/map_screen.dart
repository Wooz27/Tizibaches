import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/location_service.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/pothole.dart';
import '../../../core/map_tiles.dart';
import '../../../core/status_style.dart';
import '../../../core/widgets/pothole_mark.dart';
import '../../../core/widgets/status_widgets.dart';
import '../view_models/map_view_model.dart';
import 'pothole_detail_sheet.dart';
import 'expedientes_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.viewModel,
    required this.locationService,
    required this.onReport,
    required this.dockClearance,
  });

  final MapViewModel viewModel;
  final LocationService locationService;
  final VoidCallback onReport;
  final double dockClearance;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  bool _locating = false;

  MapViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _searchController.text = _vm.query;
    if (_vm.all.isEmpty && !_vm.loading) {
      _vm.load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final point = await widget.locationService.locate();
      _mapController.move(LatLng(point.latitude, point.longitude), 16.2);
    } on AppFailure catch (failure) {
      if (!mounted) return;
      _showMessage(failure.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showPothole(Pothole pothole) async {
    _vm.select(pothole);
    _mapController.move(
      LatLng(pothole.latitude, pothole.longitude),
      _mapController.camera.zoom < 15.5 ? 15.8 : _mapController.camera.zoom,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PotholeDetailSheet(pothole: pothole),
    );
    if (mounted) _vm.select(null);
  }

  void focusPothole(int potholeId) {
    Pothole? match;
    for (final pothole in _vm.all) {
      if (pothole.id == potholeId) {
        match = pothole;
        break;
      }
    }
    if (match == null) return;
    _mapController.move(LatLng(match.latitude, match.longitude), 16);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPothole(match!);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAttribution() async {
    final uri = Uri.parse('https://www.openstreetmap.org/copyright');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openExpedientes() async {
    final selected = await Navigator.of(context).push<Pothole>(
      MaterialPageRoute(
        builder: (context) => ExpedientesScreen(viewModel: _vm),
      ),
    );
    if (selected != null && mounted) _showPothole(selected);
  }

  Widget _buildExpedientesButton(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: widget.dockClearance + 12,
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: openExpedientes,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.onDarkLine),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.list, size: 20, color: AppColors.maize),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expedientes',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.label,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_vm.visible.length} de ${_vm.total} baches abiertos',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onDarkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Abrir',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.maize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.maize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return Stack(
            children: [
              _buildMap(),
              _buildTopOverlay(context),
              _buildMapControls(context),
              _buildExpedientesButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(AppConfig.cityLat, AppConfig.cityLon),
        initialZoom: AppConfig.cityZoom,
        minZoom: 11.5,
        maxZoom: 18,
        backgroundColor: AppColors.paperDeep,
        onTap: (_, _) => _vm.select(null),
      ),
      children: [
        ...appTileLayers(),
        MarkerLayer(
          markers: [
            for (final pothole in _vm.visible)
              Marker(
                point: LatLng(pothole.latitude, pothole.longitude),
                width: 42,
                height: 42,
                child: KeyedSubtree(
                  key: ValueKey('pothole-${pothole.id}'),
                  child: _PotholeMapMarker(
                    pothole: pothole,
                    selected: _vm.selected?.id == pothole.id,
                    onTap: () => _showPothole(pothole),
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              mapAttribution,
              onTap: _openAttribution,
              textStyle: const TextStyle(
                color: AppColors.ink,
                fontSize: 9,
                fontFamily: 'InstrumentSans',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopOverlay(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, top + 10, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bag.withValues(alpha: 0.96),
              AppColors.bag.withValues(alpha: 0.82),
              AppColors.bag.withValues(alpha: 0),
            ],
            stops: const [0, 0.72, 1],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: BrandLockup(onDark: true, compact: true)),
                _MapIconButton(
                  icon: _locating
                      ? LucideIcons.loaderCircle
                      : LucideIcons.crosshair,
                  tooltip: 'Mi ubicación',
                  onTap: _locating ? null : _locateMe,
                ),
                const SizedBox(width: 8),
                _MapIconButton(
                  icon: LucideIcons.camera,
                  tooltip: 'Reportar un bache',
                  filled: true,
                  onTap: widget.onReport,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SearchField(
              controller: _searchController,
              onChanged: _vm.setQuery,
              onClear: () {
                _searchController.clear();
                _vm.setQuery('');
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterPill(
                    label: 'Todos',
                    selected: _vm.filter == null,
                    onTap: () => _vm.setFilter(null),
                  ),
                  const SizedBox(width: 6),
                  for (final status in mapStatusFilters) ...[
                    FilterPill(
                      label: status.shortLabel,
                      status: status,
                      selected: _vm.filter == status,
                      onTap: () => _vm.setFilter(status),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 182;
    return Positioned(
      top: top,
      right: 16,
      child: Column(
        children: [
          _MapControlButton(
            icon: LucideIcons.plus,
            onTap: () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom + 1).clamp(11.5, 18),
            ),
          ),
          const SizedBox(height: 1),
          _MapControlButton(
            icon: LucideIcons.minus,
            onTap: () => _mapController.move(
              _mapController.camera.center,
              (_mapController.camera.zoom - 1).clamp(11.5, 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
      decoration: InputDecoration(
        hintText: 'Buscar calle, colonia o folio',
        fillColor: AppColors.label,
        prefixIcon: const Icon(
          LucideIcons.search,
          size: 18,
          color: AppColors.inkSoft,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(
                  LucideIcons.x,
                  size: 17,
                  color: AppColors.inkSoft,
                ),
                tooltip: 'Limpiar búsqueda',
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.maize : AppColors.label,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 19,
              color: filled ? AppColors.ink : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.label,
      borderRadius: BorderRadius.circular(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _PotholeMapMarker extends StatelessWidget {
  const _PotholeMapMarker({
    required this.pothole,
    required this.selected,
    required this.onTap,
  });

  final Pothole pothole;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = (11 + pothole.severity * 1.8).clamp(12.0, 18.0);
    return Semantics(
      button: true,
      label:
          '${pothole.status.label}, ${pothole.severityLabel}, ${pothole.displayName}, ${pothole.displayAddress}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: selected ? size + 14 : size,
            height: selected ? size + 14 : size,
            decoration: BoxDecoration(
              color: selected ? Colors.transparent : pothole.status.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.maize : AppColors.label,
                width: selected ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.14),
                  blurRadius: selected ? 0 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: size - 3,
                    height: size - 3,
                    decoration: BoxDecoration(
                      color: pothole.status.color,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
