import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      textTheme: _buildTextTheme(isDark),
      appBarTheme: _buildAppBarTheme(isDark, colorScheme),
      cardTheme: _buildCardTheme(isDark),
      inputDecorationTheme: _buildInputDecorationTheme(isDark, colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(isDark, colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(isDark, colorScheme),
      textButtonTheme: _buildTextButtonTheme(isDark, colorScheme),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkText : AppColors.text,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceRaised : AppColors.primaryLight,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkText : AppColors.primary,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor:
            isDark ? AppColors.darkAccent : AppColors.accent,
        unselectedItemColor:
            isDark ? AppColors.darkTextSubtle : AppColors.textSubtle,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceRaised : AppColors.text,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: isDark ? AppColors.darkText : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.text,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }

  // ── Color Schemes ──────────────────────────────────────────────────────────

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primaryLight,
    onSecondaryContainer: AppColors.secondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.textOnAccent,
    tertiaryContainer: AppColors.accentLight,
    onTertiaryContainer: AppColors.accentDark,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerLight,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    surfaceContainerHighest: AppColors.background,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.border,
    outlineVariant: AppColors.divider,
    shadow: Color(0x1F000000),
    scrim: Color(0x99000000),
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.primaryLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.darkPrimaryLight,
    onPrimaryContainer: AppColors.darkPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.darkPrimaryLight,
    onSecondaryContainer: AppColors.darkSecondary,
    tertiary: AppColors.darkAccent,
    onTertiary: AppColors.darkBackground,
    tertiaryContainer: AppColors.darkAccentLight,
    onTertiaryContainer: AppColors.darkAccent,
    error: AppColors.darkDanger,
    onError: AppColors.darkBackground,
    errorContainer: AppColors.darkDangerLight,
    onErrorContainer: AppColors.darkDanger,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    surfaceContainerHighest: AppColors.darkSurfaceRaised,
    onSurfaceVariant: AppColors.darkTextMuted,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkDivider,
    shadow: Color(0x3D000000),
    scrim: Color(0xCC000000),
    inverseSurface: AppColors.darkText,
    onInverseSurface: AppColors.darkSurface,
    inversePrimary: AppColors.darkPrimaryLight,
  );

  // ── Text Theme ─────────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(bool isDark) {
    final baseColor = isDark ? AppColors.darkText : AppColors.text;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.025,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.025,
        color: mutedColor,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        color: mutedColor,
      ),
    );
  }

  // ── AppBar Theme ───────────────────────────────────────────────────────────

  static AppBarTheme _buildAppBarTheme(
      bool isDark, ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surface,
      foregroundColor: isDark ? AppColors.darkText : AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.08),
      centerTitle: false,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkText : AppColors.text,
      ),
      toolbarHeight: 60,
    );
  }

  // ── Card Theme ─────────────────────────────────────────────────────────────

  static CardThemeData _buildCardTheme(bool isDark) {
    return CardThemeData(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    );
  }

  // ── Input Decoration Theme ─────────────────────────────────────────────────

  static InputDecorationTheme _buildInputDecorationTheme(
      bool isDark, ColorScheme colorScheme) {
    final fillColor =
        isDark ? AppColors.darkSurfaceRaised : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final focusedBorderColor =
        isDark ? AppColors.darkPrimary : AppColors.primary;
    final labelColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final hintColor = isDark ? AppColors.darkTextSubtle : AppColors.textSubtle;

    final borderRadius = BorderRadius.circular(12);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
            color: isDark ? AppColors.darkDanger : AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
            color: isDark ? AppColors.darkDanger : AppColors.danger,
            width: 1.5),
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: labelColor,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: hintColor,
      ),
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkDanger : AppColors.danger,
      ),
    );
  }

  // ── Elevated Button Theme ──────────────────────────────────────────────────

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
      bool isDark, ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.025,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  // ── Outlined Button Theme ──────────────────────────────────────────────────

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      bool isDark, ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        side: BorderSide(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.025,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  // ── Text Button Theme ──────────────────────────────────────────────────────

  static TextButtonThemeData _buildTextButtonTheme(
      bool isDark, ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.darkAccent : AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(0, 40),
      ),
    );
  }
}
