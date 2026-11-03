import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_dependencies.dart';
import 'core/theme/app_theme.dart';
import 'ui/features/auth/views/sign_in_screen.dart';
import 'ui/features/shell/app_shell.dart';
import 'ui/features/splash/splash_screen.dart';

class BachesApp extends StatefulWidget {
  const BachesApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<BachesApp> createState() => _BachesAppState();
}

class _BachesAppState extends State<BachesApp> {
  @override
  void initState() {
    super.initState();
    widget.dependencies.authController.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tízibaches',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnimatedBuilder(
        animation: widget.dependencies.authController,
        builder: (context, _) {
          final auth = widget.dependencies.authController;
          if (auth.booting) return const SplashScreen();
          if (auth.isSignedIn || auth.isGuest) {
            return AppShell(dependencies: widget.dependencies);
          }
          return SignInScreen(auth: auth);
        },
      ),
    );
  }
}
