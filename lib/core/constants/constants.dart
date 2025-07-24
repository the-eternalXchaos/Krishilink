import 'package:flutter/material.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

const double iconSize = 28;
const padding = EdgeInsets.all(20);

String imagePath = 'lib/core/assets/images';
String krishilinkLogo = 'lib/core/assets/images/krishilink.png';
String googleLogoPath = '$imagePath/google_logo.png';
String appleLogoPath = '$imagePath/apple_logo.png';
String facebookLogoPath = '$imagePath/facebook_logo.png';
// String defaultProfileImagePath = '$imagePath/guest.png';

String loginBackgroundPath = 'lib/core/assets/images/login_background.jpg';

String farmerIllustration = 'lib/core/components/lottie/farmer.json';
String leafScanning = 'lib/core/components/lottie/leaf_scanning.json';

String productLoading = 'lib/core/components/lottie/content_loading.json';
String profileLoading = 'lib/core/components/lottie/profile_loading.json';
String notAvailable = 'lib/core/components/lottie/not_available.json';
String emptyCart = 'lib/core/components/lottie/emptyCart.json';
String sending = 'lib/core/components/lottie/sending.json';

final String guestImage = '$imagePath/guest.png';
final String plantPlaceholder = '$imagePath/placeholder_plant.png';
final String defaultImage = '$imagePath/default_image.png';

TextTheme getTextTheme(BuildContext context) {
  return Theme.of(context).textTheme;
}

//   guest a;;opwed enfpoints ,

const List<String> guestAllowedEndpoints = [
  '/api/KrishilinkAuth/otpLogin',
  '/api/KrishilinkAuth/checkotp',
  '/api/KrishilinkAuth/registerUser',
  '/api/KrishilinkAuth/passwordLogin',
  '/api/KrishilinkAuth/verifyotp',
  '/api/KrishilinkAuth/sendOTP',
  '/api/KrishilinkAuth/verifyOTP',
  '/api/Product/getAllProducts',
  '/api/Product/getProduct',
  '/api/Product/getProductImage',
  '/api/Product/getRelatedProducts/{productId}',
  '/api/Review/getProductReviews',
  '/api/KrishilinkAuth/User/',
  '/api/KrishilinkAuth/User',
  '/products/{id}/reviews',
  '/api/Review/getProductReviews/{productId}',
  '/products/{id}/related',
  '/api/KrishilinkAuth/User/getProfile',
];

class SpacingConstants {
  // Padding
  static const double smallPadding = 8.0;
  static const double mediumPadding = 12.0;
  static const double largePadding = 16.0;
  static const double extraLargePadding = 24.0;

  // Sizing
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 22.0;
  static const double iconSizeLarge = 24.0;
  static const double avatarSize = 16.0;
  static const double lottieSizeSmall = 20.0;
  static const double lottieSizeMedium = 30.0;
  static const double lottieSizeLarge = 80.0;

  // Radius
  static const double smallRadius = 6.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;

  // Widths
  static const double messageMaxWidthFactor = 0.75;
  static const double chatHorizontalPaddingFactor = 0.04;
}
