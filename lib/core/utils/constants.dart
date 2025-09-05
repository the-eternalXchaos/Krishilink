import 'package:flutter/material.dart';

const double iconSize = 28;
const padding = EdgeInsets.all(20);

String imagePath = 'lib/core/assets/images';
String krishilinkLogo = 'lib/core/assets/images/krishilink.png';
String googleLogoPath = '$imagePath/google_logo.png';
String appleLogoPath = '$imagePath/apple_logo.png';
String facebookLogoPath = '$imagePath/facebook_logo.png';
// String defaultProfileImagePath = '$imagePath/guest.png';
String earlyBlightImage = '$imagePath/tomato_early_blight.png';

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
  '/api/Product/getAllProducts',
  '/api/Product/getProduct',
  '/api/Product/getRelatedProducts',
  '/api/Product/getRelatedProducts/{productId}',
  '/api/Product/getProductImage',
  '/api/Review/getProductReviews',
  '/api/KrishilinkAuth/otpLogin',
  '/api/KrishilinkAuth/checkotp',
  '/api/KrishilinkAuth/registerUser',
  '/api/KrishilinkAuth/passwordLogin',
  '/api/KrishilinkAuth/verifyotp',
  '/api/Weather/getWeatherDetails',
  '/api/Notification/GetNotifications',
  '/api/Notification/GetNotifications',
  // Add more if needed, but only those that exist in ApiConstants
];
