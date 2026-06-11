import 'package:flutter/material.dart';

/// OMNIGO Design System - Spacing Scale
///
/// Consistent spacing values based on a 4px grid.
abstract class OmnigoSpacing {
  // ── Raw values ─────────────────────────────────────────────────────
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;

  // ── Edge Insets helpers ────────────────────────────────────────────
  static const insetsNone = EdgeInsets.zero;

  static const insetsXxs = EdgeInsets.all(xxs);
  static const insetsXs = EdgeInsets.all(xs);
  static const insetsSm = EdgeInsets.all(sm);
  static const insetsMd = EdgeInsets.all(md);
  static const insetsLg = EdgeInsets.all(lg);
  static const insetsXl = EdgeInsets.all(xl);
  static const insetsXxl = EdgeInsets.all(xxl);

  // ── Horizontal-only ────────────────────────────────────────────────
  static const insetsHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const insetsHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const insetsHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const insetsHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const insetsHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // ── Vertical-only ──────────────────────────────────────────────────
  static const insetsVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const insetsVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const insetsVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const insetsVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const insetsVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // ── SizedBox gap helpers ───────────────────────────────────────────
  static const gapXxs = SizedBox(width: xxs, height: xxs);
  static const gapXs = SizedBox(width: xs, height: xs);
  static const gapSm = SizedBox(width: sm, height: sm);
  static const gapMd = SizedBox(width: md, height: md);
  static const gapLg = SizedBox(width: lg, height: lg);
  static const gapXl = SizedBox(width: xl, height: xl);
  static const gapXxl = SizedBox(width: xxl, height: xxl);

  // Horizontal gaps
  static const gapHXxs = SizedBox(width: xxs);
  static const gapHXs = SizedBox(width: xs);
  static const gapHSm = SizedBox(width: sm);
  static const gapHMd = SizedBox(width: md);
  static const gapHLg = SizedBox(width: lg);
  static const gapHXl = SizedBox(width: xl);

  // Vertical gaps
  static const gapVXxs = SizedBox(height: xxs);
  static const gapVXs = SizedBox(height: xs);
  static const gapVSm = SizedBox(height: sm);
  static const gapVMd = SizedBox(height: md);
  static const gapVLg = SizedBox(height: lg);
  static const gapVXl = SizedBox(height: xl);
  static const gapVXxl = SizedBox(height: xxl);
  static const gapVXxxl = SizedBox(height: xxxl);

  // ── Border radius ──────────────────────────────────────────────────
  static const radiusXs = BorderRadius.all(Radius.circular(xxs));
  static const radiusSm = BorderRadius.all(Radius.circular(xs));
  static const radiusMd = BorderRadius.all(Radius.circular(sm));
  static const radiusLg = BorderRadius.all(Radius.circular(md));
  static const radiusXl = BorderRadius.all(Radius.circular(xl));
  static const radiusFull = BorderRadius.all(Radius.circular(9999));
}
