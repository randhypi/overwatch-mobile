import 'package:flutter/material.dart';

extension ResponsiveUtil on BuildContext {
  /// Check if the current screen is a tablet based on the shortest side
  /// Standard breakpoint for tablets is 600dp
  bool get isTablet {
    final shortestSide = MediaQuery.of(this).size.shortestSide;
    return shortestSide >= 600;
  }

  /// Check if the screen is large (e.g., Desktop or large Tablet in landscape)
  bool get isLargeScreen {
    return MediaQuery.of(this).size.width >= 1024;
  }
}
