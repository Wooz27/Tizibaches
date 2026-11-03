import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'core/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(BachesApp(dependencies: AppDependencies.create()));
}
