import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_dependencies.dart';
import '../../../core/theme/app_colors.dart';
import '../../core/widgets/app_dock.dart';
import '../auth/view_models/auth_controller.dart';
import '../auth/views/auth_prompt_sheet.dart';
import '../map/view_models/map_view_model.dart';
import '../map/views/map_screen.dart';
import '../profile/views/profile_screen.dart';
import '../report/views/report_screen.dart';
import '../reports/view_models/my_reports_view_model.dart';
import '../reports/views/my_reports_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _mapKey = GlobalKey<MapScreenState>();
  int _index = 0;

  MapViewModel get _map => widget.dependencies.mapViewModel;
  MyReportsViewModel get _reports => widget.dependencies.myReportsViewModel;
  AuthController get _auth => widget.dependencies.authController;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_handleAuthChanged);
    _applyOverlay(0);
    _map.load();
    if (_auth.isSignedIn) _reports.load();
  }

  void _applyOverlay(int index) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: index == 0
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _selectSection(int index) {
    _applyOverlay(index);
    setState(() => _index = index);
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    super.dispose();
  }

  void _handleAuthChanged() {
    if (_auth.isSignedIn) {
      _reports.load();
    } else {
      _reports.clear();
    }
  }

  Future<void> _openReport() async {
    if (!_auth.isSignedIn) {
      final signedIn = await _promptSignIn();
      if (!signedIn) return;
    }
    if (!mounted) return;

    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          controller: widget.dependencies.createReportController(),
          auth: _auth,
        ),
      ),
    );

    _applyOverlay(_index);
    if (submitted == true) {
      await _map.refresh();
      if (_auth.isSignedIn) await _reports.refresh();
      if (mounted) _selectSection(0);
    }
  }

  Future<bool> _promptSignIn() async {
    if (_auth.isSignedIn) return true;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthPromptSheet(auth: _auth),
    );
    return result == true && _auth.isSignedIn;
  }

  void _openPotholeOnMap(int potholeId) {
    setState(() => _index = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.focusPothole(potholeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dockClearance = 68 + 12 + MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.ink,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.label,
        body: IndexedStack(
          index: _index,
          children: [
            MapScreen(
              key: _mapKey,
              viewModel: _map,
              locationService: widget.dependencies.locationService,
              onReport: _openReport,
              dockClearance: dockClearance,
            ),
            MyReportsScreen(
              auth: _auth,
              viewModel: _reports,
              onReport: _openReport,
              onSignIn: _promptSignIn,
              onOpenMap: _openPotholeOnMap,
              dockClearance: dockClearance,
            ),
            ProfileScreen(
              auth: _auth,
              onSignIn: _promptSignIn,
              onOpenMap: () => setState(() => _index = 0),
              dockClearance: dockClearance,
            ),
          ],
        ),
        bottomNavigationBar: AppDock(
          selectedIndex: _index,
          onSelect: _selectSection,
          onReport: _openReport,
        ),
      ),
    );
  }
}
