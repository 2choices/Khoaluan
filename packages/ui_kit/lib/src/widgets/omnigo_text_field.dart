import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/omnigo_colors.dart';
import '../theme/omnigo_spacing.dart';
import '../theme/omnigo_typography.dart';

/// A styled text field aligned with the OMNIGO design system.
///
/// Wraps [TextFormField] with consistent styling, optional [label],
/// [hint], [prefixIcon], [suffixIcon], and [errorText].
class OmnigoTextField extends StatelessWidget {
  const OmnigoTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.prefix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Label displayed above the field.
  final String? label;

  /// Placeholder text when field is empty.
  final String? hint;

  /// Helper text shown below the field (hidden when [errorText] is set).
  final String? helperText;

  /// Error message shown below the field. Triggers error styling.
  final String? errorText;

  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final Widget? prefix;

  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBorderRadius = borderRadius ?? OmnigoSpacing.radiusSm;
    final effectiveFillColor = fillColor ??
        (isDark ? OmnigoColors.darkSurface : OmnigoColors.surface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label ────────────────────────────────────────────────
        if (label != null) ...[
          Text(
            label!,
            style: OmnigoTypography.labelLarge.copyWith(
              color: isDark
                  ? OmnigoColors.darkTextPrimary
                  : OmnigoColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: OmnigoSpacing.xs),
        ],

        // ── Input ────────────────────────────────────────────────
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          style: OmnigoTypography.bodyMedium.copyWith(
            color: isDark
                ? OmnigoColors.darkTextPrimary
                : OmnigoColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: errorText == null ? helperText : null,
            filled: true,
            fillColor: effectiveFillColor,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: OmnigoSpacing.md,
                  vertical: OmnigoSpacing.sm,
                ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: 20,
                    color: isDark
                        ? OmnigoColors.darkTextHint
                        : OmnigoColors.textHint,
                  )
                : prefix,
            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    size: 20,
                    color: isDark
                        ? OmnigoColors.darkTextHint
                        : OmnigoColors.textHint,
                  )
                : suffix,
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color:
                    isDark ? OmnigoColors.darkBorder : OmnigoColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color:
                    isDark ? OmnigoColors.darkBorder : OmnigoColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color: isDark
                    ? OmnigoColors.primaryLight
                    : OmnigoColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(color: OmnigoColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide:
                  const BorderSide(color: OmnigoColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: BorderSide(
                color:
                    isDark ? OmnigoColors.darkDivider : OmnigoColors.divider,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
