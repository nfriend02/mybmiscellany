import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appColors.dart';

const desktopBreakpoint = 960.0;

TextStyle orbitron(
  double size, {
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w700,
}) {
  return GoogleFonts.orbitron(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0.6,
  );
}

TextStyle pixel(double size, {Color color = AppColors.neonGreen}) {
  return GoogleFonts.pressStart2p(fontSize: size, color: color, height: 1.6);
}

TextStyle bodyText({
  double size = 14,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w400,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: 1.5,
  );
}

TextStyle labelText({
  double size = 13,
  Color color = AppColors.muted,
  FontWeight weight = FontWeight.w600,
}) {
  return GoogleFonts.roboto(fontSize: size, color: color, fontWeight: weight);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.blue)
      .copyWith(primary: AppColors.blue, surface: Colors.white);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.roboto(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.blue,
      thumbColor: AppColors.neonPurple,
      inactiveTrackColor: AppColors.line,
    ),
    dividerColor: AppColors.line,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: GoogleFonts.inter(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      indicatorColor: AppColors.neonGreen.withValues(alpha: 0.45),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.roboto(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blueBright, width: 1.6),
      ),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
