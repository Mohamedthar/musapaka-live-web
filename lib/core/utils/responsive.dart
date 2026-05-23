import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

enum ScreenType { mobile, tablet, desktop }

class ResponsiveUtils {
  static ScreenType fromWidth(double width) {
    if (width < Breakpoints.mobile) return ScreenType.mobile;
    if (width < Breakpoints.tablet) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      fromWidth(MediaQuery.of(context).size.width) == ScreenType.mobile;

  static bool isTablet(BuildContext context) =>
      fromWidth(MediaQuery.of(context).size.width) == ScreenType.tablet;

  static bool isDesktop(BuildContext context) =>
      fromWidth(MediaQuery.of(context).size.width) == ScreenType.desktop;

  static EdgeInsets padding(ScreenType type) {
    switch (type) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(24);
      case ScreenType.desktop:
        return const EdgeInsets.all(32);
    }
  }
}
