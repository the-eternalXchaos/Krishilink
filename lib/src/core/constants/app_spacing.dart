import 'package:flutter/widgets.dart';

/// Consistent spacing, sizes, and radii for the app
class AppSpacing {
  /// Raw numeric values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Ready-to-use paddings
  static const smallPadding = EdgeInsets.all(sm);
  static const mediumPadding = EdgeInsets.all(md);
  static const largePadding = EdgeInsets.all(lg);
  static const extraLargePadding = EdgeInsets.all(xl);

  /// Icon sizes
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 22.0;
  static const double iconSizeLarge = 28.0;

  /// Avatar size
  static const double avatarSize = 40.0;

  /// Lottie sizes
  static const double lottieSmall = 20.0;
  static const double lottieMedium = 30.0;
  static const double lottieLarge = 80.0;

  /// Radius
  static const double smallRadius = 6.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;

  /// Width factors
  static const double messageMaxWidthFactor = 0.75;
  static const double chatHorizontalPaddingFactor = 0.04;
}
