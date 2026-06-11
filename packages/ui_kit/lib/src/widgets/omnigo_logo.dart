import 'package:flutter/material.dart';

import '../theme/omnigo_colors.dart';

class OmnigoLogo extends StatelessWidget {
  static const assetPath = 'assets/logo/omnigo-logo.jpg';

  final double size;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const OmnigoLogo({
    super.key,
    this.size = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          assetPath,
          fit: fit,
          errorBuilder: (_, _, _) => ColoredBox(
            color: OmnigoColors.primary,
            child: Center(
              child: Text(
                'O',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
