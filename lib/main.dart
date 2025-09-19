// /*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_link/core/controllers/language_controller.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/core/components/confirm%20box/custom_confirm_dialog.dart';
import 'package:krishi_link/src/core/config/architecture_config.dart';
import 'package:krishi_link/core/bindings/admin_binding.dart' hide AdminBinding;
import 'package:krishi_link/src/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/core/controllers/settings_controller.dart';
import 'package:krishi_link/core/screens/unified_settings_page.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/translations/app_translations.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/src/core/services/connectivity_service.dart';
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
import 'package:krishi_link/features/payment/screens/payment_history_screen.dart';
import 'package:krishi_link/features/payment/screens/payment_webview_screen.dart';
import 'package:krishi_link/features/order_summary/screens/order_summary_page.dart';
import 'package:krishi_link/features/order_summary/bindings/order_summary_binding.dart';
import 'package:krishi_link/core/bindings/app_binding.dart';
import 'package:krishi_link/features/buyer/bindings/buyer_binding.dart';
import 'package:krishi_link/features/product/bindings/product_detail_binding.dart';
import 'package:krishi_link/features/farmer/bindings/farmer_binding.dart';
import 'package:krishi_link/features/admin/bindings/admin_binding.dart';
import 'package:krishi_link/features/payment/bindings/payment_binding.dart';
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
import 'package:krishi_link/guest_product_binding.dart';
import 'package:krishi_link/services/device_service.dart';
import 'package:krishi_link/features/notification/screens/notifications.dart';
import 'package:krishi_link/features/product/screens/product_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krishi_link/src/core/networking/dio_provider.dart';

import 'package:krishi_link/src/core/components/product/management/unified_product_management.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Allow public routes first - no auth check needed
    if (route == '/welcome' ||
        route == '/splash' ||
        route == '/login' ||
        route == '/register') {
      return null;
    }

    // Check if AuthController exists, if not, redirect to login
    if (!Get.isRegistered<AuthController>()) {
      return const RouteSettings(name: '/login');
    }

    try {
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;

      // If we have tokens saved but last refresh failed due to network issues,
      // do NOT force redirect while offline. Let the user continue and try later.
      if (TokenService.lastRefreshWasNetworkError) {
        PopupService.warning(
          'You appear to be offline. Some actions may be unavailable.',
          title: 'Network Issue',
        );
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
          PopupService.error(
            'no_permission'.tr,
            title: 'unauthorized_access'.tr,
          );
          return RouteSettings(name: '/$role-dashboard');
        }
      }

      return null;
    } catch (e) {
      // If AuthController access fails, redirect to login
      debugPrint('AuthMiddleware error: $e');
      return const RouteSettings(name: '/login');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services in parallel where possible
  await Future.wait([GetStorage.init(), Hive.initFlutter()]);

  // Initialize new feature-first architecture
  await ArchitectureConfig.initialize();

  // Initialize device service
  final deviceService = DeviceService();
  final prefs = await SharedPreferences.getInstance();

  // Initialize device ID only if not exists
  if (prefs.getString('deviceId') == null) {
    final deviceId = await deviceService.getDeviceId();
    await prefs.setString('deviceId', deviceId);
    debugPrint('[Main] Initialized deviceId: $deviceId');
  }

  // Determine initial route
  final String initialRoute = await _determineInitialRoute(prefs);

  // IMPORTANT: Register all global controllers BEFORE any splash or navigation logic runs.
  // This ensures Get.find() always works in splash and throughout the app.
  _initializeControllers();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _determineInitialRoute(SharedPreferences prefs) async {
  // Always start with splash screen
  return '/splash';
}

void _initializeControllers() {
  // Global controllers - always available throughout app lifecycle
  Get.put(AuthController(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  // Central Dio provider (lazy singleton with fenix)
  registerDioProvider();

  // Re-creatable global controllers (created when needed, can be recreated)
  Get.lazyPut(() => SettingsController(), fenix: true);

  // Note: CartController will be lazy-loaded only for authenticated users
  // ProductBinding and AdminBinding are now handled per-page, not globally
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => CustomConfirmDialog(
                title: 'Are you sure?',
                content: 'Do you want to exit the App?',
                confirmText: 'Yes',
                cancelText: 'No',
                onConfirm: () {
                  Navigator.of(context).pop(true); // Return true
                  SystemNavigator.pop();
                },
                onCancel: () {
                  Navigator.of(context).pop(false); // Return false
                },
              ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // Pop only if user confirmed
        }
      },
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: languageController.currentLocale,

        fallbackLocale: const Locale('en', 'US'),
        // Removed initialBinding to prevent early controller initialization
        // ProductBinding will be initialized only when needed on specific pages
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
            binding: GuestProductBinding(),
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
            binding: FarmerBinding(),
            middlewares: [AuthMiddleware()],
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: '/buyer-dashboard',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              return BuyerHomePage(isGuest: args?['isGuest'] ?? true);
            },
            binding: BuyerBinding(),
            middlewares: [AuthMiddleware()],
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: '/product-details',
            page: () {
              return ProductDetailPage(product: Get.arguments);
            },
            binding: ProductDetailBinding(),
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
          GetPage(
            name: '/farmer-orders',
            page: () => const FarmerOrdersScreen(),
          ),
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
            binding: BuyerBinding(),
          ),
          GetPage(
            name: '/checkout',
            page: () => const CheckoutScreen(),
            binding: BuyerBinding(),
          ),
          GetPage(
            name: '/payment-history',
            page: () => const PaymentHistoryScreen(),
            binding: PaymentBinding(),
          ),
          GetPage(
            name: '/payment-webview',
            page: () {
              final args = Get.arguments as Map<String, dynamic>?;
              final paymentUrl =
                  args?['paymentUrl'] as String? ?? args?['url'] as String?;
              if (paymentUrl == null) {
                // If arguments missing, pop back safely
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.back();
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return PaymentWebViewScreen(url: paymentUrl);
            },
            binding: PaymentBinding(),
          ),
          GetPage(
            name: '/orders/summary',
            page: () => const OrderSummaryPage(),
            binding: OrderSummaryBinding(),
            middlewares: [AuthMiddleware()],
            transition: Transition.fadeIn,
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
      ),
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
// import 'package:krishi_link/mock_login.dart'; // COMMENTED OUT - Mock login disabled
import 'package:krishi_link/product_binding.dart';
import 'package:krishi_link/features/notification/screens/notifications.dart';
import 'package:krishi_link/features/product/screens/product_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    // Allow public routes
    if (route == '/welcome' ||
        route == '/login' ||
        route == '/register') {
        // route == '/mock-login') { // COMMENTED OUT - Mock login disabled
      return null;
    }

    // Block authenticated users from going back to welcome/login/register
    if (currentUser != null) {
      if (route == '/welcome' ||
          route == '/login' ||
          route == '/register') {
          // route == '/mock-login') { // COMMENTED OUT - Mock login disabled
        final role = currentUser.role.toLowerCase();
        return RouteSettings(name: '/$role-dashboard');
      }
    }

    // Check authentication
    if (currentUser == null) {
      PopupService.error('Please login to access this feature', title: 'Authentication Required');
      return const RouteSettings(
        name: '/login', // Changed from '/mock-login' to '/login'
      ); // Redirect to login instead of mock-login
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
    const MyApp(initialRoute: '/welcome'), // Changed from '/mock-login' to '/welcome'
  ); // Mock login disabled - using normal flow
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
        // GetPage( // COMMENTED OUT - Mock login disabled
        //   name: '/mock-login',
        //   page: () => const MockLoginScreen(),
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
                  Get.offNamed('/login'); // Changed from '/mock-login' to '/login'
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
                Get.offNamed('/login'); // Changed from '/mock-login' to '/login'
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
