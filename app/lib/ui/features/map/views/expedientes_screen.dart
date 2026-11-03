import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/status_style.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/status_widgets.dart';
import '../view_models/map_view_model.dart';
import 'pothole_list_card.dart';

class ExpedientesScreen extends StatefulWidget {
  const ExpedientesScreen({super.key, required this.viewModel});

  final MapViewModel viewModel;

  @override
  State<ExpedientesScreen> createState() => _ExpedientesScreenState();
}

class _ExpedientesScreenState extends State<ExpedientesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = widget.viewModel.query;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.label,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(2),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
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
                      const Text(
                        'Expedientes',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${vm.visible.length} de ${vm.total}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: vm.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar calle, colonia o folio',
                      fillColor: AppColors.paper,
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.inkSoft,
                      ),
                      suffixIcon: vm.query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                vm.setQuery('');
                              },
                              icon: const Icon(
                                LucideIcons.x,
                                size: 17,
                                color: AppColors.inkSoft,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      FilterPill(
                        label: 'Todos',
                        selected: vm.filter == null,
                        onTap: () => vm.setFilter(null),
                      ),
                      const SizedBox(width: 6),
                      for (final status in mapStatusFilters) ...[
                        FilterPill(
                          label: status.shortLabel,
                          status: status,
                          selected: vm.filter == status,
                          onTap: () => vm.setFilter(status),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: vm.visible.isEmpty
                      ? SingleChildScrollView(
                          child: EmptyState(
                            title: 'No hay expedientes con ese filtro.',
                            message:
                                'Prueba con otra calle, otro estado o limpia la búsqueda.',
                            actionLabel: 'Limpiar filtros',
                            onAction: () {
                              _search.clear();
                              vm.clearFilters();
                            },
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            4,
                            18,
                            20 + MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          itemCount: vm.visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final pothole = vm.visible[index];
                            return PotholeListCard(
                              pothole: pothole,
                              onTap: () => Navigator.of(context).pop(pothole),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
