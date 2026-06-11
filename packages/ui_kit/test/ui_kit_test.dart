import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui_kit/ui_kit.dart';

void main() {
  group('OmnigoColors', () {
    test('primary color has correct hex value', () {
      expect(OmnigoColors.primary, const Color(0xFFC84B1A));
    });

    test('error color has correct hex value', () {
      expect(OmnigoColors.error, const Color(0xFFC62828));
    });

    test('dark mode colors are defined', () {
      expect(OmnigoColors.darkBackground, isNotNull);
      expect(OmnigoColors.darkSurface, isNotNull);
      expect(OmnigoColors.darkTextPrimary, isNotNull);
    });
  });

  group('OmnigoSpacing', () {
    test('spacing values follow 4px grid', () {
      expect(OmnigoSpacing.xxs, 4);
      expect(OmnigoSpacing.xs, 8);
      expect(OmnigoSpacing.sm, 12);
      expect(OmnigoSpacing.md, 16);
      expect(OmnigoSpacing.lg, 20);
      expect(OmnigoSpacing.xl, 24);
      expect(OmnigoSpacing.xxl, 32);
      expect(OmnigoSpacing.xxxl, 48);
      expect(OmnigoSpacing.xxxxl, 64);
    });

    test('edge insets are symmetric', () {
      expect(OmnigoSpacing.insetsMd, const EdgeInsets.all(16));
    });

    test('border radii are defined', () {
      expect(OmnigoSpacing.radiusSm, isA<BorderRadius>());
      expect(OmnigoSpacing.radiusLg, isA<BorderRadius>());
    });
  });
}
