import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'omnigo_colors.dart';
import 'omnigo_spacing.dart';
import 'omnigo_typography.dart';

/// OMNIGO Design System - Theme Builder
///
/// Combines colors, typography, and component themes into complete
/// [ThemeData] for both light and dark modes.
abstract class OmnigoTheme {
  // ═══════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get light {
    final textTheme = OmnigoTypography.textTheme.apply(
      bodyColor: OmnigoColors.textPrimary,
      displayColor: OmnigoColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: OmnigoColors.primary,
      scaffoldBackgroundColor: OmnigoColors.background,
      textTheme: textTheme,

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: OmnigoColors.background,
        foregroundColor: OmnigoColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: OmnigoTypography.titleLarge.copyWith(
          color: OmnigoColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: OmnigoColors.textPrimary,
          size: 24,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: OmnigoColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusLg,
          side: const BorderSide(color: OmnigoColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OmnigoColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OmnigoColors.border,
          disabledForegroundColor: OmnigoColors.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusFull,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Filled Button ────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OmnigoColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OmnigoColors.border,
          disabledForegroundColor: OmnigoColors.textHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusFull,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OmnigoColors.primary,
          disabledForegroundColor: OmnigoColors.textHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusFull,
          ),
          side: const BorderSide(color: OmnigoColors.border),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OmnigoColors.primary,
          disabledForegroundColor: OmnigoColors.textHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.md,
            vertical: OmnigoSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusFull,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 40),
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnigoColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.md,
          vertical: OmnigoSpacing.sm,
        ),
        hintStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.textHint,
        ),
        labelStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.textSecondary,
        ),
        errorStyle: OmnigoTypography.bodySmall.copyWith(
          color: OmnigoColors.error,
        ),
        border: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.divider),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: OmnigoColors.chipBackground,
        selectedColor: OmnigoColors.primaryLight.withValues(alpha: 0.45),
        labelStyle: OmnigoTypography.labelMedium,
        side: const BorderSide(color: OmnigoColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusFull,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.sm,
          vertical: OmnigoSpacing.xxs,
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: OmnigoColors.surface,
        selectedItemColor: OmnigoColors.primary,
        unselectedItemColor: OmnigoColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: OmnigoTypography.labelSmall,
        unselectedLabelStyle: OmnigoTypography.labelSmall,
      ),

      // ── Navigation Bar (Material 3) ─────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OmnigoColors.surface,
        indicatorColor: OmnigoColors.primaryLight.withValues(alpha: 0.45),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return OmnigoTypography.labelSmall.copyWith(
              color: OmnigoColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return OmnigoTypography.labelSmall.copyWith(
            color: OmnigoColors.textHint,
          );
        }),
      ),

      // ── Divider ──────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: OmnigoColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: OmnigoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusXl,
        ),
        titleTextStyle: OmnigoTypography.titleLarge.copyWith(
          color: OmnigoColors.textPrimary,
        ),
        contentTextStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.textSecondary,
        ),
      ),

      // ── Snackbar ─────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmnigoColors.textPrimary,
        contentTextStyle: OmnigoTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusSm,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Floating Action Button ───────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OmnigoColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusLg,
        ),
      ),

      // ── TabBar ───────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: OmnigoColors.primary,
        labelColor: OmnigoColors.primary,
        unselectedLabelColor: OmnigoColors.textSecondary,
        labelStyle: OmnigoTypography.labelLarge,
        unselectedLabelStyle: OmnigoTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════

  static ThemeData get dark {
    final textTheme = OmnigoTypography.textTheme.apply(
      bodyColor: OmnigoColors.darkTextPrimary,
      displayColor: OmnigoColors.darkTextPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: OmnigoColors.primary,
      scaffoldBackgroundColor: OmnigoColors.darkBackground,
      textTheme: textTheme,

      // ── AppBar ───────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: OmnigoColors.darkSurface,
        foregroundColor: OmnigoColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: OmnigoTypography.titleLarge.copyWith(
          color: OmnigoColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: OmnigoColors.darkTextPrimary,
          size: 24,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: OmnigoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusLg,
          side: const BorderSide(color: OmnigoColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OmnigoColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OmnigoColors.darkBorder,
          disabledForegroundColor: OmnigoColors.darkTextHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusSm,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Filled Button ────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OmnigoColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: OmnigoColors.darkBorder,
          disabledForegroundColor: OmnigoColors.darkTextHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusSm,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OmnigoColors.primaryLight,
          disabledForegroundColor: OmnigoColors.darkTextHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.xl,
            vertical: OmnigoSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusSm,
          ),
          side: const BorderSide(color: OmnigoColors.darkBorder),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OmnigoColors.primaryLight,
          disabledForegroundColor: OmnigoColors.darkTextHint,
          padding: const EdgeInsets.symmetric(
            horizontal: OmnigoSpacing.md,
            vertical: OmnigoSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: OmnigoSpacing.radiusSm,
          ),
          textStyle: OmnigoTypography.labelLarge,
          minimumSize: const Size(0, 40),
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OmnigoColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.md,
          vertical: OmnigoSpacing.sm,
        ),
        hintStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.darkTextHint,
        ),
        labelStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.darkTextSecondary,
        ),
        errorStyle: OmnigoTypography.bodySmall.copyWith(
          color: OmnigoColors.error,
        ),
        border: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide:
              const BorderSide(color: OmnigoColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: OmnigoSpacing.radiusSm,
          borderSide: const BorderSide(color: OmnigoColors.darkDivider),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: OmnigoColors.darkSurface,
        selectedColor: OmnigoColors.primaryLight.withValues(alpha: 0.2),
        labelStyle: OmnigoTypography.labelMedium.copyWith(
          color: OmnigoColors.darkTextPrimary,
        ),
        side: const BorderSide(color: OmnigoColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusFull,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.sm,
          vertical: OmnigoSpacing.xxs,
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: OmnigoColors.darkSurface,
        selectedItemColor: OmnigoColors.primaryLight,
        unselectedItemColor: OmnigoColors.darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: OmnigoTypography.labelSmall,
        unselectedLabelStyle: OmnigoTypography.labelSmall,
      ),

      // ── Navigation Bar (Material 3) ─────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OmnigoColors.darkSurface,
        indicatorColor: OmnigoColors.primaryLight.withValues(alpha: 0.2),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return OmnigoTypography.labelSmall.copyWith(
              color: OmnigoColors.primaryLight,
              fontWeight: FontWeight.w600,
            );
          }
          return OmnigoTypography.labelSmall.copyWith(
            color: OmnigoColors.darkTextHint,
          );
        }),
      ),

      // ── Divider ──────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: OmnigoColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ───────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: OmnigoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusXl,
        ),
        titleTextStyle: OmnigoTypography.titleLarge.copyWith(
          color: OmnigoColors.darkTextPrimary,
        ),
        contentTextStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.darkTextSecondary,
        ),
      ),

      // ── Snackbar ─────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OmnigoColors.darkTextPrimary,
        contentTextStyle: OmnigoTypography.bodyMedium.copyWith(
          color: OmnigoColors.darkBackground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusSm,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Floating Action Button ───────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OmnigoColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: OmnigoSpacing.radiusLg,
        ),
      ),

      // ── TabBar ───────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        indicatorColor: OmnigoColors.primaryLight,
        labelColor: OmnigoColors.primaryLight,
        unselectedLabelColor: OmnigoColors.darkTextSecondary,
        labelStyle: OmnigoTypography.labelLarge,
        unselectedLabelStyle: OmnigoTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }
}
