import 'package:flutter/material.dart';

import '../theme/omnigo_colors.dart';
import '../theme/omnigo_spacing.dart';
import '../theme/omnigo_typography.dart';

/// A styled card aligned with the OMNIGO design system.
///
/// Supports an optional [header] row (title + action), configurable
/// [padding], [elevation], and [onTap] interaction.
class OmnigoCard extends StatelessWidget {
  const OmnigoCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.padding,
    this.headerPadding,
    this.elevation,
    this.color,
    this.borderColor,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.clipBehavior = Clip.antiAlias,
    this.margin,
  });

  /// Main content of the card.
  final Widget? child;

  /// Optional header title text.
  final String? title;

  /// Optional subtitle below the title.
  final String? subtitle;

  /// Widget at the trailing end of the header (e.g. an icon button).
  final Widget? trailing;

  /// Widget at the leading end of the header (e.g. an icon or avatar).
  final Widget? leading;

  /// Padding around the [child]. Defaults to 16px all.
  final EdgeInsets? padding;

  /// Padding around the header row. Defaults to 16px horizontal, 12px vertical.
  final EdgeInsets? headerPadding;

  /// Card elevation. Defaults to 0 (flat card with border).
  final double? elevation;

  /// Background color override.
  final Color? color;

  /// Border color override.
  final Color? borderColor;

  /// Border radius override.
  final BorderRadius? borderRadius;

  /// Tap handler. When set, the card gets an InkWell ripple.
  final VoidCallback? onTap;

  /// Long-press handler.
  final VoidCallback? onLongPress;

  /// Show a divider between header and content. Defaults to `true`.
  final bool showDivider;

  /// Clip behaviour.
  final Clip clipBehavior;

  /// Outer margin.
  final EdgeInsets? margin;

  bool get _hasHeader => title != null || trailing != null || leading != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveColor =
        color ?? (isDark ? OmnigoColors.darkSurface : OmnigoColors.surface);
    final effectiveBorder =
        borderColor ?? (isDark ? OmnigoColors.darkBorder : OmnigoColors.border);
    final effectiveRadius = borderRadius ?? OmnigoSpacing.radiusLg;
    final effectivePadding = padding ?? OmnigoSpacing.insetsMd;
    final effectiveHeaderPadding = headerPadding ??
        const EdgeInsets.symmetric(
          horizontal: OmnigoSpacing.md,
          vertical: OmnigoSpacing.sm,
        );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ─────────────────────────────────────────────
        if (_hasHeader) ...[
          Padding(
            padding: effectiveHeaderPadding,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: OmnigoSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: OmnigoTypography.titleMedium.copyWith(
                            color: isDark
                                ? OmnigoColors.darkTextPrimary
                                : OmnigoColors.textPrimary,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: OmnigoTypography.bodySmall.copyWith(
                            color: isDark
                                ? OmnigoColors.darkTextSecondary
                                : OmnigoColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (showDivider && child != null)
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? OmnigoColors.darkDivider : OmnigoColors.divider,
            ),
        ],

        // ── Body ───────────────────────────────────────────────
        if (child != null)
          Padding(
            padding: effectivePadding,
            child: child,
          ),
      ],
    );

    return Card(
      elevation: elevation ?? 0,
      color: effectiveColor,
      surfaceTintColor: Colors.transparent,
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: clipBehavior,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: BorderSide(color: effectiveBorder, width: 1),
      ),
      child: onTap != null || onLongPress != null
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: effectiveRadius,
              child: content,
            )
          : content,
    );
  }
}
