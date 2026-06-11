import 'package:flutter/material.dart';

const customerCompactWidth = 600.0;
const customerRailWidth = 900.0;
const customerWideWidth = 1200.0;
const customerMaxContentWidth = 1180.0;
const customerMaxRouteWidth = 960.0;

class CustomerResponsive {
  static bool useRailNavigation(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= customerRailWidth;
  }

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < customerCompactWidth;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= customerWideWidth) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    if (width >= customerCompactWidth) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static EdgeInsets headerPadding(BuildContext context, {double bottom = 12}) {
    final horizontal = pagePadding(context).horizontal / 2;
    final top = useRailNavigation(context) ? 24.0 : 56.0;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static int productColumns(double width) {
    if (width >= 1080) return 5;
    if (width >= 820) return 4;
    if (width >= 560) return 3;
    return 2;
  }

  static double productAspectRatio(double width) {
    if (width >= 820) return 0.76;
    return 0.72;
  }
}

class CustomerResponsivePane extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CustomerResponsivePane({
    super.key,
    required this.child,
    this.maxWidth = customerMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (!CustomerResponsive.useRailNavigation(context)) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class CustomerResponsiveRoute extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CustomerResponsiveRoute({
    super.key,
    required this.child,
    this.maxWidth = customerMaxRouteWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (!CustomerResponsive.useRailNavigation(context)) {
      return child;
    }

    return ColoredBox(
      color: const Color(0xFFFFF5F0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
