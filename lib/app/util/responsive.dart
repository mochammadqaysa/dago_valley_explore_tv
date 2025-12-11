import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth &&
      MediaQuery.of(context).size.width < tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  // Responsive value based on screen size
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Responsive padding
  static double horizontalPadding(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  static double verticalPadding(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }

  // Responsive font size
  static double fontSize(BuildContext context, double baseSize) {
    return value<double>(
      context: context,
      mobile: baseSize,
      tablet: baseSize * 1.2,
      desktop: baseSize * 1.4,
    );
  }

  // Responsive spacing
  static double spacing(BuildContext context, double baseSpacing) {
    return value<double>(
      context: context,
      mobile: baseSpacing,
      tablet: baseSpacing * 1.2,
      desktop: baseSpacing * 1.5,
    );
  }

  // Grid cross axis count
  static int gridCrossAxisCount(BuildContext context) {
    return value<int>(context: context, mobile: 1, tablet: 2, desktop: 3);
  }

  // Max content width
  static double maxContentWidth(BuildContext context) {
    return value<double>(
      context: context,
      mobile: double.infinity,
      tablet: 900,
      desktop: 1400,
    );
  }
}
