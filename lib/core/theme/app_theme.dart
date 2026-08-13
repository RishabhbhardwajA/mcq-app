import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ExamGuard Emerald Glass Design System
/// Dark glassmorphism theme with emerald green + mint accents
class AppTheme {
  AppTheme._();

  // ─── Core Colors ───
  static const Color background = Color(0xFF0A0F0D);
  static const Color surfaceDark = Color(0xFF0D1B14);
  static const Color surfaceContainer = Color(0xFF151B18);

  static const Color emerald = Color(0xFF34D399);
  static const Color emeraldDim = Color(0xFF059669);
  static const Color mint = Color(0xFF6EE7B7);
  static const Color lightMint = Color(0xFFA7F3D0);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textMuted = Color(0x66FFFFFF);     // 40% white

  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);

  // ─── Glass Colors ───
  static const Color glassBackground = Color(0x0DFFFFFF);   // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF);        // 10% white
  static const Color glassBackgroundHover = Color(0x14FFFFFF);// 8% white
  static Color emeraldGlow = emerald.withValues(alpha: 0.3);
  static Color emeraldBorder = emerald.withValues(alpha: 0.2);

  // ─── Gradients ───
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0F0D),
      Color(0xFF0D1B14),
      Color(0xFF0A1510),
    ],
  );

  static LinearGradient emeraldButtonGradient = LinearGradient(
    colors: [emerald, emeraldDim],
  );

  // ─── Text Styles ───
  static TextStyle get headlineXL => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLG => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
  );

  static TextStyle get headlineMD => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineSM => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyLG => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMD => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySM => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );

  static TextStyle get labelMD => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static TextStyle get labelSM => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );

  // ─── Glass Decorations ───
  static BoxDecoration get glassCard => BoxDecoration(
    color: glassBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: glassBorder, width: 1),
  );

  static BoxDecoration get glassCardEmerald => BoxDecoration(
    color: glassBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: emeraldBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: emerald.withValues(alpha: 0.08),
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get glassInput => BoxDecoration(
    color: Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: glassBorder, width: 1),
  );

  static BoxDecoration get glassInputFocused => BoxDecoration(
    color: Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: emerald, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: emerald.withValues(alpha: 0.15),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );

  // ─── ThemeData ───
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.dark(
      primary: emerald,
      secondary: mint,
      tertiary: lightMint,
      surface: surfaceContainer,
      error: error,
      onPrimary: Color(0xFF003120),
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    textTheme: TextTheme(
      headlineLarge: headlineLG,
      headlineMedium: headlineMD,
      headlineSmall: headlineSM,
      bodyLarge: bodyLG,
      bodyMedium: bodyMD,
      bodySmall: bodySM,
      labelMedium: labelMD,
      labelSmall: labelSM,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: emerald,
        foregroundColor: const Color(0xFF003120),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: emerald,
        side: BorderSide(color: emeraldBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x14FFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: emerald, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      prefixIconColor: textMuted,
      suffixIconColor: textMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: glassBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: glassBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceContainer,
      contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: headlineSM,
      contentTextStyle: bodyLG,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: glassBorder),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: emerald,
    ),
    dividerTheme: DividerThemeData(
      color: glassBorder,
      thickness: 1,
    ),
  );
}
