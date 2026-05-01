import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Shared color constants — import this file from anywhere that needs them.
abstract class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const bg          = Color(0xFF161618); // near-black charcoal
  static const surface     = Color(0xFF1C1C1E); // card / sheet
  static const surfaceHigh = Color(0xFF242428); // elevated element, input fill
  static const border      = Color(0xFF2C2C2E); // subtle border
  static const divider     = Color(0xFF38383A); // separator line

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFEAEAEF); // off-white
  static const textSecondary = Color(0xFF8E8E93); // muted label
  static const textTertiary  = Color(0xFF48484A); // very muted

  // ── Accent — muted steel blue (calm, focused) ────────────────────────
  static const accent    = Color(0xFF5B7FA8);
  static const accentDim = Color(0xFF142438); // very muted bg behind accent

  // ── Semantic ─────────────────────────────────────────────────────────────────
  static const gold    = Color(0xFFFFD700);
  static const green   = Color(0xFF34C759); // Apple green — success / done
  static const red     = Color(0xFFFF453A); // Apple red
  static const orange  = Color(0xFFFF9F0A);
  static const purple  = Color(0xFFBF5AF2);
}

class AppTheme {
  static ThemeData get light {
    const accent = AppColors.accent;
    const bg = Color(0xFFF2F2F7);
    const surface = Colors.white;
    const textPrimary = Color(0xFF1C1C1E);
    const textSecondary = Color(0xFF6E6E73);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      primaryColor: accent,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        secondary: accent,
        onSecondary: Colors.white,
        surfaceContainerHighest: Color(0xFFE5E5EA),
        outline: Color(0xFFD1D1D6),
      ),
      cardColor: surface,
      dividerColor: const Color(0xFFD1D1D6),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.8),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.4),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, letterSpacing: -0.2),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        labelLarge: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        labelSmall: TextStyle(color: textSecondary, fontSize: 11, letterSpacing: 0.6),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
        iconTheme: IconThemeData(color: textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : const Color(0xFFBCBCC0)),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : const Color(0xFFE5E5EA)),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 15),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFE5E5EA),
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get dark {
    const accent = AppColors.accent;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: accent,

      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        secondary: accent,
        onSecondary: Colors.white,
        surfaceContainerHighest: AppColors.surfaceHigh,
        outline: AppColors.border,
      ),

      cardColor: AppColors.surface,
      dividerColor: AppColors.divider,

      // ── Typography ─────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 34,
            letterSpacing: -0.8),
        titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.4),
        titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.2),
        bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            letterSpacing: -0.2),
        bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14),
        labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1),
        labelSmall: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.6),
      ),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),

      // ── Bottom Nav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: accent,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        // Hairline top border via decoration is set per-widget; theme handles colors only
      ),

      // ── Buttons ─────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),

      // ── Inputs ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        hintStyle: const TextStyle(
            color: AppColors.textTertiary, fontSize: 15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),

      // ── Switch ──────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? accent
                : AppColors.surfaceHigh),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Tab bar ─────────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.1),
        unselectedLabelStyle: TextStyle(fontSize: 13),
      ),

      // ── Dialogs ─────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600),
        contentTextStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 15),
      ),

      // ── List tiles ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),

      // ── Snack bars ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
