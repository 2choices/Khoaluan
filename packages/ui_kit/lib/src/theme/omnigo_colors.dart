import 'package:flutter/material.dart';

/// OMNIGO Design System - Color Palette
///
/// Based on OMNIGO's warm commerce palette with semantic naming.
abstract class OmnigoColors {
  // ── Primary - warm yellow/orange ───────────────────────────────────
  static const primary = Color(0xFFC84B1A);
  static const primaryLight = Color(0xFFFFD8B8);
  static const primaryDark = Color(0xFFA33A12);

  // ── Secondary - teal ───────────────────────────────────────────────
  static const secondary = Color(0xFFE7A93C);
  static const secondaryLight = Color(0xFFFFE7AD);
  static const secondaryDark = Color(0xFFB77912);

  // ── Semantic ───────────────────────────────────────────────────────
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFE7A93C);
  static const info = Color(0xFF2563EB);

  // ── Neutral / Surface ──────────────────────────────────────────────
  static const background = Color(0xFFFFF5F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFBF8);
  static const chipBackground = Color(0xFFFFF3E0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textHint = Color(0xFF999999);
  static const border = Color(0xFFE8DDD6);
  static const divider = Color(0xFFF0E3DC);

  // ── Dark-mode equivalents ──────────────────────────────────────────
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextHint = Color(0xFF64748B);
  static const darkBorder = Color(0xFF334155);
  static const darkDivider = Color(0xFF1E293B);

  // ── Material color swatch (for primarySwatch) ──────────────────────
  static const MaterialColor primarySwatch = MaterialColor(
    0xFFC84B1A,
    <int, Color>{
      50: Color(0xFFFFF5F0),
      100: Color(0xFFFFE5D9),
      200: Color(0xFFFFD8B8),
      300: Color(0xFFF4B184),
      400: Color(0xFFE57E48),
      500: Color(0xFFC84B1A),
      600: Color(0xFFA33A12),
      700: Color(0xFF7C2A0B),
      800: Color(0xFF5E1F08),
      900: Color(0xFF421406),
    },
  );
}
