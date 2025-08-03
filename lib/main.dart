// /*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:krishi_link/core/bindings/admin_binding.dart';
import 'package:krishi_link/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/core/controllers/settings_controller.dart';
import 'package:krishi_link/core/screens/unified_settings_page.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/translations/app_translations.dart';
import 'package:krishi_link/features/admin/controllers/admin_product_controller.dart';
import 'package:krishi_link/features/admin/screens/admin_home_page.dart';
import 'package:krishi_link/features/admin/screens/analytics_screen.dart';
import 'package:krishi_link/features/admin/screens/category_screen.dart';
import 'package:krishi_link/features/admin/screens/content_moderation_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_orders_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_products_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_users_screen.dart';
import 'package:krishi_link/features/admin/screens/reports_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/auth/screens/otp_verification_screen.dart';
import 'package:krishi_link/features/auth/screens/register_screen.dart';
import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
import 'package:krishi_link/features/buyer/screens/checkout_screen.dart';
import 'package:krishi_link/features/buyer/screens/wishlist_screen.dart';
import 'package:krishi_link/features/disease_detection/screens/disease_detection_screen.dart';
import 'package:krishi_link/features/farmer/screens/farmer_home_page.dart';
import 'package:krishi_link/features/farmer/screens/farmer_orders_screen.dart';
import 'package:krishi_link/features/farmer/screens/order_details_screen.dart';
import 'package:krishi_link/features/farmer/screens/tutorial_details.dart';
import 'package:krishi_link/features/farmer/screens/tutorials.dart';
import 'package:krishi_link/features/onboarding/screens/splash_screen.dart';
import 'package:krishi_link/features/onboarding/screens/welcome_page.dart';
import 'package:krishi_link/features/profile/profile_screen.dart';
import 'package:krishi_link/product_binding.dart';
import 'package:krishi_link/services/device_service.dart';
import 'package:krishi_link/widgets/notifications.dart';
import 'package:krishi_link/widgets/product_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/components/product/management/unified_product_management.dart';
import 'core/controllers/language_controller.dart';
import 'core/lottie/popup_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    // Allow public routes
    if (route == '/welcome' ||
        // route == '/splash' ||
        route == '/login' ||
        route == '/register') {
      return null;
    }

    // Block authenticated users from going back to welcome/login/register
    if (currentUser != null) {
      if (route == '/welcome' ||
          route == '/login' ||
          // route == '/product-details' ||
          route == '/register') {
        final role = currentUser.role.toLowerCase();
        return RouteSettings(name: '/$role-dashboard');
      }
    }

    // Check authentication
    if (currentUser == null) {
      PopupService.error(
        'please_login_to_access'.tr,
        title: 'authentication_required'.tr,
      );
      return const RouteSettings(name: '/login');
    }

    // Check role-based access
    if (route!.contains('-dashboard')) {
      final role = currentUser.role.toLowerCase();
      if (!route.contains(role)) {
        PopupService.error('no_permission'.tr, title: 'unauthorized_access'.tr);
        return RouteSettings(name: '/$role-dashboard');
      }
    }

    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize GetStorage
  await GetStorage.init();
  // Initialize deviceId

  final deviceService = DeviceService();
  final deviceId = await deviceService.getDeviceId();
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('deviceId') == null) {
    await prefs.setString('deviceId', deviceId);
    debugPrint('[Main] Initialized deviceId: $deviceId');
  }
  // final prefs = await SharedPreferences.getInstance();
  final expiration = prefs.getString('expiration');
  String initialRoute = '/welcome'; // Default to welcome page
  // Initialize settings first to ensure theme and locale are ready
  // Load saved language before app starts
  if (expiration != null) {
    final expiryDate = DateTime.parse(expiration);
    if (DateTime.now().isAfter(expiryDate)) {
      await prefs.clear(); // Clear all stored data
      initialRoute = '/login';
    } else {
      final role = prefs.getString('role')?.toLowerCase() ?? '';
      switch (role) {
        case 'admin':
          initialRoute = '/admin-dashboard';
          break;
        case 'farmer':
          initialRoute = '/farmer-dashboard';
          break;
        case 'buyer':
          initialRoute = '/buyer-dashboard';
          break;
        default:
          debugPrint('[AUTH] Unknown role detected. Redirecting to welcome.');

          initialRoute = '/welcome';
          break;
      }
    }
  }
  // Initialize core controllers
  // Get.put(AuthController());
  Get.lazyPut(() => AuthController());
  Get.lazyPut(() => ProductBinding());
  Get.lazyPut(() => AdminBinding());
  Get.lazyPut(() => SettingsController());
  // Get.put(ProductBinding());
  Get.put(AdminBinding());
  Get.put(SettingsController());

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return GetMaterialApp(
      translations: AppTranslations(),
      locale: languageController.currentLocale,

      fallbackLocale: const Locale('en', 'US'),
      initialBinding: ProductBinding(),
      navigatorKey: Get.key,
      title: 'Krishi Link'.tr,
      debugShowCheckedModeBanner: false,

      // theme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
          transition: Transition.fade,
        ),
        GetPage(
          name: '/welcome',
          page: () => const WelcomePage(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fade,
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/admin-dashboard',
          page: () => const AdminHomePage(),
          bindings: [AdminBinding(), ProductBinding()],
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/farmer-dashboard',
          page: () => const FarmerHomePage(),
          binding: ProductBinding(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/buyer-dashboard',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return BuyerHomePage(isGuest: args?['isGuest'] ?? true);
          },
          binding: ProductBinding(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/product-details',
          page: () {
            return ProductDetailPage(product: Get.arguments);
          },
          binding: ProductBinding(),
        ),
        GetPage(
          name: '/settings',
          page: () => const UnifiedSettingsPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/farmer-tutorials',
          page: () => TutorialsScreen(),
        ), // Stub
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ), // Stub
        GetPage(
          name: '/disease-detection',
          page: () => DiseaseDetectionScreen(),
        ),
        GetPage(name: '/farmer-orders', page: () => const FarmerOrdersScreen()),
        GetPage(
          name: '/admin/products',
          page: () => UnifiedProductManagement(),
          binding: BindingsBuilder(() {
            Get.lazyPut<UnifiedProductController>(
              () => UnifiedProductController(),
            );
          }),
        ),
        GetPage(
          name: '/product-management',
          page: () => UnifiedProductManagement(),
        ),
        GetPage(
          name: '/order-details',
          page: () => OrderDetailsScreen(order: Get.arguments),
        ),
        GetPage(
          name: '/tutorial-details',
          page: () => TutorialDetailsScreen(tutorial: Get.arguments),
        ),
        GetPage(name: '/profile-screen', page: () => ProfileScreen()),
        GetPage(
          name: '/wishlist',
          page: () => const WishlistScreen(),
          binding: ProductBinding(),
        ),
        GetPage(
          name: '/checkout',
          page: () => const CheckoutScreen(),
          binding: ProductBinding(),
        ),
        // GetPage(
        //   name: '/otp-verify',
        //   page: () {
        //     final args = Get.arguments as Map<String, dynamic>;
        //     if (!args.containsKey('identifier') ||
        //         !args.containsKey('isEmail')) {
        //       Get.offNamed('/login');
        //       throw ArgumentError(
        //         'Missing required OTP verification parameters',
        //       );
        //     }
        //     return OtpVerificationScreen(
        //       identifier: args['identifier'],
        //       isEmail: args['isEmail'],
        //     );
        //   },
        //   transition: Transition.fadeIn,
        // ),
        GetPage(
          name: '/otp-verify',
          page: () {
            try {
              final args = Get.arguments as Map<String, dynamic>?;
              if (args == null || !args.containsKey('identifier')) {
                debugPrint('[NAV] Missing OTP verification parameters');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offNamed('/login');
                });
                return const SizedBox(); // Fallback widget
              }

              debugPrint(
                '[NAV] Navigating to OTP verification for: ${args['identifier']}',
              );
              return OtpVerificationScreen(identifier: args['identifier']);
            } catch (e, stackTrace) {
              debugPrint('[NAV] Error in OTP verification navigation: $e');
              debugPrint(stackTrace.toString());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offNamed('/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ); // Fallback widget
            }
          },
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/admin/dashboard',
          page: () => const AdminHomePage(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/users',
          page: () => const ManageUsersScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/products',
          page: () => UnifiedProductManagement(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/orders',
          page: () => const ManageOrdersScreen(),
          binding: AdminBinding(),
        ),
        // GetPage(
        //   name: '/admin/marketplace',
        //   page: () => const AdminMarketplace(),
        //   binding: AdminBinding(),
        // ),
        GetPage(
          name: '/admin/categories',
          page: () => const CategoryScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/analytics',
          page: () => const AnalyticsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/notifications',
          page: () => const NotificationsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/reports',
          page: () => const ReportsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/moderation',
          page: () => const ContentModerationScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/settings',
          // page: () => const SettingsScreen(),
          page: () => const UnifiedSettingsPage(),
          binding: AdminBinding(),
        ),
      ],
    );
  }
}

// /**/

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/theme/app_theme.dart';
// import 'package:krishi_link/features/admin/screens/admin_home_page.dart';

// class AppTheme {
//   static ThemeData get theme {
//     return ThemeData(
//       primarySwatch: Colors.blue,
//       // Add other theme properties here
//     );
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Krishi Link',
//       theme: AppTheme.theme, // Use the static getter to get ThemeData
//       initialRoute: '/admin-dashboard',
//       getPages: [
//         GetPage(name: '/admin-dashboard', page: () => const AdminHomePage()),
//       ],
//     );
//   }
// }
/**
 * 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishi_link/core/bindings/admin_binding.dart';
import 'package:krishi_link/core/controllers/settings_controller.dart';
import 'package:krishi_link/core/screens/unified_settings_page.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/translations/app_translations.dart';
import 'package:krishi_link/features/admin/screens/admin_home_page.dart';
import 'package:krishi_link/features/admin/screens/analytics_screen.dart';
import 'package:krishi_link/features/admin/screens/category_screen.dart';
import 'package:krishi_link/features/admin/screens/content_moderation_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_orders_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_products_screen.dart';
import 'package:krishi_link/features/admin/screens/manage_users_screen.dart';
import 'package:krishi_link/features/admin/screens/notifications_screen.dart';
import 'package:krishi_link/features/admin/screens/reports_screen.dart';
import 'package:krishi_link/features/admin/screens/settings_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/auth/screens/otp_verification_screen.dart';
import 'package:krishi_link/features/auth/screens/register_screen.dart';
import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
import 'package:krishi_link/features/disease_detection/screens/disease_detection_screen.dart';
import 'package:krishi_link/features/farmer/controller/product_management.dart';
import 'package:krishi_link/features/farmer/screens/farmer_home_page.dart';
import 'package:krishi_link/features/farmer/screens/farmer_orders_screen.dart';
import 'package:krishi_link/features/farmer/screens/farmer_settings.dart';
import 'package:krishi_link/features/farmer/screens/order_details_screen.dart';
import 'package:krishi_link/features/farmer/screens/tutorial_details.dart';
import 'package:krishi_link/features/farmer/screens/tutorials.dart';
import 'package:krishi_link/features/onboarding/screens/welcome_page.dart';
import 'package:krishi_link/mock_login.dart';
import 'package:krishi_link/product_binding.dart';
import 'package:krishi_link/widgets/notifications.dart';
import 'package:krishi_link/widgets/product_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    // Allow public routes
    if (route == '/welcome' ||
        route == '/login' ||
        route == '/register' ||
        route == '/mock-login') {
      return null;
    }

    // Block authenticated users from going back to welcome/login/register/mock-login
    if (currentUser != null) {
      if (route == '/welcome' ||
          route == '/login' ||
          route == '/register' ||
          route == '/mock-login') {
        final role = currentUser.role.toLowerCase();
        return RouteSettings(name: '/$role-dashboard');
      }
    }

    // Check authentication
    if (currentUser == null) {
      PopupService.error('Please login to access this feature', title: 'Authentication Required');
      return const RouteSettings(
        name: '/mock-login',
      ); // Redirect to mock-login instead of login
    }

    // Check role-based access
    if (route!.contains('-dashboard')) {
      final role = currentUser.role.toLowerCase();
      if (!route.contains(role)) {
        PopupService.error('You do not have permission to access this area', title: 'Unauthorized Access');
        return RouteSettings(name: '/$role-dashboard');
      }
    }

    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings first to ensure theme and locale are ready
  final settingsController = Get.put(SettingsController());
  await settingsController.loadSettings();

  // Initialize core controllers
  Get.put(ProductBinding());
  Get.put(AdminBinding());

  runApp(
    const MyApp(initialRoute: '/mock-login'),
  ); // Force mock-login for testing
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: Get.deviceLocale ?? const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true); // Single initialization
      }),
      navigatorKey: Get.key,
      title: 'Krishi Link',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      defaultTransition: Transition.fadeIn,
      getPages: [
        GetPage(
          name: '/welcome',
          page: () => const WelcomePage(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fade,
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/admin-dashboard',
          page: () => const AdminHomePage(),
          bindings: [AdminBinding(), ProductBinding()],
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/farmer-dashboard',
          page: () => const FarmerHomePage(),
          binding: ProductBinding(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/buyer-dashboard',
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            return BuyerHomePage(isGuest: args?['isGuest'] ?? true);
          },
          binding: ProductBinding(),
          middlewares: [AuthMiddleware()],
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/product-details',
          page: () => ProductDetailPage(product: Get.arguments),
          binding: ProductBinding(),
        ),
        GetPage(
          name: '/settings',
          page: () => const UnifiedSettingsPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(name: '/farmer-tutorials', page: () => TutorialsScreen()),
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ),
        GetPage(
          name: '/disease-detection',
          page: () => const DiseaseDetectionScreen(),
        ),
        GetPage(name: '/farmer-orders', page: () => const FarmerOrdersScreen()),
        GetPage(
          name: '/product-management',
          page: () => const FarmerProductManagementScreen(),
        ),
        GetPage(
          name: '/order-details',
          page: () => OrderDetailsScreen(order: Get.arguments),
        ),
        GetPage(
          name: '/tutorial-details',
          page: () => TutorialDetailsScreen(tutorial: Get.arguments),
        ),
        GetPage(
          name: '/mock-login',
          page: () => const MockLoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/otp-verify',
          page: () {
            try {
              final args = Get.arguments as Map<String, dynamic>?;
              if (args == null || !args.containsKey('identifier')) {
                debugPrint('[NAV] Missing OTP verification parameters');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.offNamed('/mock-login');
                });
                return const SizedBox();
              }
              debugPrint(
                '[NAV] Navigating to OTP verification for: ${args['identifier']}',
              );
              return OtpVerificationScreen(identifier: args['identifier']);
            } catch (e, stackTrace) {
              debugPrint('[NAV] Error in OTP verification navigation: $e');
              debugPrint(stackTrace.toString());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offNamed('/mock-login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/admin/dashboard',
          page: () => const AdminHomePage(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/users',
          page: () => const ManageUsersScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/products',
          page: () => ManageProductsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/orders',
          page: () => const ManageOrdersScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/categories',
          page: () => const CategoryScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/analytics',
          page: () => const AnalyticsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/notifications',
          page: () => const NotificationsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/reports',
          page: () => const ReportsScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/moderation',
          page: () => const ContentModerationScreen(),
          binding: AdminBinding(),
        ),
        GetPage(
          name: '/admin/settings',
          page: () => const SettingsScreen(),
          binding: AdminBinding(),
        ),
      ],
    );
  }
}

//  */
