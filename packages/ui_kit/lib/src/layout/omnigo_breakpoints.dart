import 'package:flutter/widgets.dart';

abstract class OmnigoBreakpoints {
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compact;
  }

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compact && width < expanded;
  }

  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= expanded;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return const EdgeInsets.all(12);
    if (width < expanded) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }

  static double constrainedContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return width;
    if (width < expanded) return 960;
    return 1180;
  }
}
