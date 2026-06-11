import 'package:flutter/material.dart';

import '../theme/omnigo_colors.dart';
import '../theme/omnigo_spacing.dart';

/// Button variant types for [OmnigoButton].
enum OmnigoButtonVariant {
  /// Solid primary background.
  primary,

  /// Lighter secondary background.
  secondary,

  /// Bordered outline, no fill.
  outline,

  /// Text-only, no background or border.
  text,
}

/// Button size presets.
enum OmnigoButtonSize {
  small,
  medium,
  large,
}

/// A versatile button widget aligned with the OMNIGO design system.
///
/// Supports [OmnigoButtonVariant] styles, a [loading] state, and optional
/// [prefixIcon] / [suffixIcon].
class OmnigoButton extends StatelessWidget {
  const OmnigoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = OmnigoButtonVariant.primary,
    this.size = OmnigoButtonSize.medium,
    this.loading = false,
    this.expanded = false,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius,
  });

  /// Button text label.
  final String label;

  /// Tap handler. Pass `null` to disable the button.
  final VoidCallback? onPressed;

  /// Visual variant.
  final OmnigoButtonVariant variant;

  /// Size preset.
  final OmnigoButtonSize size;

  /// When `true`, disables interaction and shows a spinner.
  final bool loading;

  /// When `true`, the button stretches to fill available width.
  final bool expanded;

  /// Optional icon shown before the label.
  final IconData? prefixIcon;

  /// Optional icon shown after the label.
  final IconData? suffixIcon;

  /// Custom border radius override.
  final BorderRadius? borderRadius;

  // ── Size helpers ─────────────────────────────────────────────────

  double get _height {
    return switch (size) {
      OmnigoButtonSize.small => 36,
      OmnigoButtonSize.medium => 48,
      OmnigoButtonSize.large => 56,
    };
  }

  EdgeInsets get _padding {
    return switch (size) {
      OmnigoButtonSize.small => const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.md,
          vertical: OmnigoSpacing.xxs,
        ),
      OmnigoButtonSize.medium => const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.xl,
          vertical: OmnigoSpacing.xs,
        ),
      OmnigoButtonSize.large => const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.xxl,
          vertical: OmnigoSpacing.sm,
        ),
    };
  }

  double get _iconSize {
    return switch (size) {
      OmnigoButtonSize.small => 16,
      OmnigoButtonSize.medium => 20,
      OmnigoButtonSize.large => 24,
    };
  }

  double get _fontSize {
    return switch (size) {
      OmnigoButtonSize.small => 13,
      OmnigoButtonSize.medium => 14,
      OmnigoButtonSize.large => 16,
    };
  }

  double get _spinnerSize {
    return switch (size) {
      OmnigoButtonSize.small => 14,
      OmnigoButtonSize.medium => 18,
      OmnigoButtonSize.large => 22,
    };
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    final effectiveBorderRadius = borderRadius ?? OmnigoSpacing.radiusFull;

    final child = _buildChild(context);

    Widget button = switch (variant) {
      OmnigoButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(0, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        ),
      OmnigoButtonVariant.secondary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: OmnigoColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: Size(0, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        ),
      OmnigoButtonVariant.outline => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        ),
      OmnigoButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(0, _height),
            padding: _padding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        ),
    };

    if (expanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: _spinnerSize,
        height: _spinnerSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == OmnigoButtonVariant.primary ||
                    variant == OmnigoButtonVariant.secondary
                ? Colors.white
                : OmnigoColors.primary,
          ),
        ),
      );
    }

    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
      ),
    );

    if (prefixIcon == null && suffixIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: _iconSize),
          SizedBox(width: OmnigoSpacing.xs),
        ],
        textWidget,
        if (suffixIcon != null) ...[
          SizedBox(width: OmnigoSpacing.xs),
          Icon(suffixIcon, size: _iconSize),
        ],
      ],
    );
  }
}
