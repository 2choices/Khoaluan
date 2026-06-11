import 'package:flutter/material.dart';

import '../theme/omnigo_colors.dart';
import '../theme/omnigo_spacing.dart';

/// Size presets for [OmnigoLoading].
enum OmnigoLoadingSize {
  small,
  medium,
  large,
}

/// A loading spinner aligned with the OMNIGO design system.
///
/// Can optionally display a [message] below the spinner.
class OmnigoLoading extends StatelessWidget {
  const OmnigoLoading({
    super.key,
    this.size = OmnigoLoadingSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
  });

  final OmnigoLoadingSize size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  double get _dimension {
    return switch (size) {
      OmnigoLoadingSize.small => 20,
      OmnigoLoadingSize.medium => 36,
      OmnigoLoadingSize.large => 56,
    };
  }

  double get _strokeWidth {
    return strokeWidth ??
        switch (size) {
          OmnigoLoadingSize.small => 2,
          OmnigoLoadingSize.medium => 3,
          OmnigoLoadingSize.large => 4,
        };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? OmnigoColors.primary;

    final spinner = SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
      ),
    );

    if (message == null) return spinner;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        spinner,
        const SizedBox(height: OmnigoSpacing.sm),
        Text(
          message!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: OmnigoColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  SHIMMER PLACEHOLDER
// ═════════════════════════════════════════════════════════════════════

/// A shimmering placeholder used while content is loading.
///
/// Mimics the shape of real content with a subtle animated gradient sweep.
class OmnigoShimmer extends StatefulWidget {
  const OmnigoShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<OmnigoShimmer> createState() => _OmnigoShimmerState();
}

class _OmnigoShimmerState extends State<OmnigoShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? OmnigoSpacing.radiusXs,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A multi-line shimmer placeholder that mimics a text block.
class OmnigoShimmerTextBlock extends StatefulWidget {
  const OmnigoShimmerTextBlock({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.lineSpacing = 10,
    this.lastLineWidthFraction = 0.65,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  final int lines;
  final double lineHeight;
  final double lineSpacing;
  final double lastLineWidthFraction;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<OmnigoShimmerTextBlock> createState() => _OmnigoShimmerTextBlockState();
}

class _OmnigoShimmerTextBlockState extends State<OmnigoShimmerTextBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF475569) : const Color(0xFFF1F5F9));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final gradient = LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: [base, highlight, base],
          stops: const [0.0, 0.5, 1.0],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.lines, (index) {
            final isLast = index == widget.lines - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : widget.lineSpacing,
              ),
              child: FractionallySizedBox(
                widthFactor: isLast ? widget.lastLineWidthFraction : 1.0,
                child: Container(
                  height: widget.lineHeight,
                  decoration: BoxDecoration(
                    borderRadius:
                        widget.borderRadius ?? OmnigoSpacing.radiusXs,
                    gradient: gradient,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// A circular shimmer placeholder (e.g. for avatars).
class OmnigoShimmerCircle extends StatelessWidget {
  const OmnigoShimmerCircle({
    super.key,
    this.size = 48,
    this.baseColor,
    this.highlightColor,
  });

  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return OmnigoShimmer(
      width: size,
      height: size,
      borderRadius: OmnigoSpacing.radiusFull,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}
