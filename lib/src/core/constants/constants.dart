import 'package:flutter/material.dart';

/// =====================
/// 📌 Global Constants
/// =====================
const double kDefaultIconSize = 28.0;
const EdgeInsets kDefaultPadding = EdgeInsets.all(20);

TextTheme getTextTheme(BuildContext context) {
  return Theme.of(context).textTheme;
}

/// =====================
/// 📌 Asset Paths
/// =====================
const String _imagePath = 'lib/src/core/assets/images';
const String _lottiePath = 'lib/src/core/components/lottie';

class AssetPaths {
  // Logos & Images
  static const String krishilinkLogo = '$_imagePath/krishilink.png';
  static const String googleLogo = '$_imagePath/google_logo.png';
  static const String appleLogo = '$_imagePath/apple_logo.png';
  static const String facebookLogo = '$_imagePath/facebook_logo.png';
  static const String guestImage = '$_imagePath/guest.png';
  static const String plantPlaceholder = '$_imagePath/placeholder_plant.png';
  static const String defaultImage = '$_imagePath/default_image.png';
  static const String loginBackground = '$_imagePath/login_background.jpg';
  static const String earlyBlight = '$_imagePath/tomato_early_blight.png';

  // Lottie Animations
  static const String farmerIllustration = '$_lottiePath/farmer.json';
  static const String leafScanning = '$_lottiePath/leaf_scanning.json';
  static const String productLoading = '$_lottiePath/content_loading.json';
  static const String profileLoading = '$_lottiePath/profile_loading.json';
  static const String notAvailable = '$_lottiePath/not_available.json';
  static const String emptyCart = '$_lottiePath/emptyCart.json';
  static const String sending = '$_lottiePath/sending.json';
}

/// =====================
/// 📌 Guest-Allowed API Endpoints
/// =====================
const List<String> guestAllowedEndpoints = [
  // 🔐 Auth
  '/api/KrishilinkAuth/otpLogin',
  '/api/KrishilinkAuth/checkotp',
  '/api/KrishilinkAuth/registerUser',
  '/api/KrishilinkAuth/passwordLogin',
  '/api/KrishilinkAuth/verifyotp',
  '/api/KrishilinkAuth/sendOTP',
  '/api/KrishilinkAuth/verifyOTP',

  // 🛒 Product
  '/api/Product/getAllProducts',
  '/api/Product/getProduct',
  '/api/Product/getProductImage',
  '/api/Product/getRelatedProducts',
  '/api/Product/getRelatedProducts/{productId}',

  // ⭐ Reviews
  '/api/Review/getProductReviews',
  '/api/Review/getProductReviews/{productId}',
  '/products/{id}/reviews',
  '/products/{id}/related',

  // 👤 User (limited guest access)
  '/api/KrishilinkAuth/User/',
  '/api/KrishilinkAuth/User',
  '/api/KrishilinkAuth/User/getProfile',

  // 🌦️ Weather & 🔔 Notifications
  '/api/Weather/getWeatherDetails',
  '/api/Notification/GetNotifications',
];
