import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette and type from the JapsPos `/customer` web portal (`--ca-*` tokens).
class CaColors {
  static const Color brand = Color(0xFFE11D48);
  static const Color brandDark = Color(0xFFBE123C);
  static const Color brandMid = Color(0xFFFB7185);
  static const Color brandSoft = Color(0xFFFFF1F2);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red50 = Color(0xFFFEF2F2);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color line = Color(0x140F172A);
  static const Color surface = Color(0xD1FFFFFF);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);

  static const Color green600 = Color(0xFF16A34A);
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color rose900 = Color(0xFF9F1239);

  static const LinearGradient brandGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [brand, brandDark]);
  static const LinearGradient logoGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE11D2E), Color(0xFFEC4899)]);
}

/// Headings use Outfit, body text DM Sans, like the portal.
TextStyle display({double size = 16, FontWeight weight = FontWeight.w800, Color color = CaColors.ink, double? height}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color, letterSpacing: -0.02 * size, height: height);

ThemeData buildCaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: CaColors.brand, primary: CaColors.brand, surface: Colors.white),
    scaffoldBackgroundColor: CaColors.slate50,
  );
  final text = GoogleFonts.dmSansTextTheme(base.textTheme).apply(bodyColor: CaColors.ink, displayColor: CaColors.ink);
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: CaColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: display(size: 17),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: CaColors.slate400, fontSize: 15, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CaColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CaColors.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: CaColors.brand, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CaColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CaColors.slate600,
        side: const BorderSide(color: CaColors.slate200),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? CaColors.brand : null)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
