import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.maize,
      onPrimary: AppColors.ink,
      primaryContainer: AppColors.maize,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.sky,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.paperDeep,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.clay,
      onTertiary: AppColors.label,
      error: AppColors.clayDeep,
      onError: AppColors.label,
      surface: AppColors.label,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkSoft,
      outline: AppColors.inkSoft,
      outlineVariant: AppColors.line,
      shadow: Colors.transparent,
      scrim: AppColors.ink,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.label,
      inversePrimary: AppColors.maize,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.label,
      canvasColor: AppColors.label,
      fontFamily: 'InstrumentSans',
      fontFamilyFallback: const ['Roboto', 'sans-serif'],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: BachesPageTransitionsBuilder(),
          TargetPlatform.linux: BachesPageTransitionsBuilder(),
          TargetPlatform.windows: BachesPageTransitionsBuilder(),
          TargetPlatform.macOS: BachesPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontSize: 46,
        height: 0.94,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.1,
      ),
      displayMedium: const TextStyle(
        fontSize: 38,
        height: 0.96,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
      ),
      headlineLarge: const TextStyle(
        fontSize: 30,
        height: 1.02,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: const TextStyle(
        fontSize: 25,
        height: 1.05,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14.5,
        height: 1.45,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
      ),
      bodySmall: const TextStyle(
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: const TextStyle(
        fontSize: 10.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(2),
      borderSide: const BorderSide(color: AppColors.line),
    );

    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      primaryTextTheme: textTheme.apply(
        bodyColor: AppColors.label,
        displayColor: AppColors.label,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.maize,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: AppColors.paperDeep,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.lineStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.ink,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.ink, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.clayDeep, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: AppColors.clayDeep, width: 1.4),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.clayDeep),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.label,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.label,
        modalBarrierColor: Color(0x9908120D),
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.label,
        ),
        actionTextColor: AppColors.maize,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.paperDeep,
        circularTrackColor: AppColors.paperDeep,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.label),
        side: const BorderSide(color: AppColors.inkSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}

class BachesPageTransitionsBuilder extends PageTransitionsBuilder {
  const BachesPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
