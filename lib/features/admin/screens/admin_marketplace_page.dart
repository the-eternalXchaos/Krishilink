// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/controllers/component_animation_controller.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller_new.dart';
// import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
// import 'package:krishi_link/features/marketplace/screens/marketplace_page.dart'; // Adjust path as needed
// import 'package:krishi_link/widgets/custom_app_bar.dart';
// import 'package:visibility_detector/visibility_detector.dart';

// class AdminMarketplacePage extends StatelessWidget {
//   const AdminMarketplacePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authController = Get.find<AuthController>();
//     final isLoggedIn = authController.isLoggedIn;
//     final user = authController.currentUser;

//     // Admin role check
//     if (!isLoggedIn || user.value?.role != 'admin') {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Get.offAllNamed('/login');
//         Get.snackbar('Access Denied', 'Admin access required');
//       });
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

//     // Trigger initial animation
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Get.find<ComponentAnimationController>(tag: 'marketplace').animate();
//     });

//     return Scaffold(
//       appBar: CustomAppBar(isGuest: !isLoggedIn || user.value == null),
//       body: Row(
//         children: [
//           if (isWideScreen) _buildMenuSidebar(context), // Reuse sidebar
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Theme.of(context).colorScheme.primaryContainer,
//                     Theme.of(context).colorScheme.surface,
//                     Colors.green.shade200.withAlpha(204),
//                   ],
//                 ),
//               ),
//               child: SafeArea(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildMarketplace(context),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMarketplace(BuildContext context) {
//     return Obx(() {
//       final controller = Get.find<ComponentAnimationController>(
//         tag: 'marketplace',
//       );
//       return VisibilityDetector(
//         key: const Key('marketplace'),
//         onVisibilityChanged: (info) {
//           if (!Get.isRegistered<ComponentAnimationController>(
//             tag: 'marketplace',
//           ))
//             return;
//           if (info.visibleFraction > 0.5) {
//             controller.animate();
//           } else if (info.visibleFraction < 0.1) {
//             controller.reset();
//           }
//         },
//         child: AnimatedOpacity(
//           opacity: controller.isVisible.value ? 1.0 : 0.0,
//           duration: const Duration(milliseconds: 600),
//           curve: Curves.easeInOut,
//           child: ScaleTransition(
//             scale: controller.animation,
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Marketplace',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const SizedBox(height: 10),
//                   BuyerHomePage(), // Reuse buyer's marketplace
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildMenuSidebar(BuildContext context) {
//     final navItems = [
//       {
//         'route': '/admin/dashboard',
//         'icon': Icons.dashboard,
//         'label': 'Dashboard',
//       },
//       {'route': '/admin/users', 'icon': Icons.person, 'label': 'Users'},
//       {
//         'route': '/admin/marketplace',
//         'icon': Icons.store_mall_directory_rounded,
//         'label': 'Marketplace',
//       },
//       {'route': '/admin/products', 'icon': Icons.grass, 'label': 'Products'},
//       {
//         'route': '/admin/orders',
//         'icon': Icons.shopping_cart,
//         'label': 'Orders',
//       },
//       {
//         'route': '/admin/categories',
//         'icon': Icons.category,
//         'label': 'Categories',
//       },
//       {
//         'route': '/admin/analytics',
//         'icon': Icons.analytics,
//         'label': 'Analytics',
//       },
//       {
//         'route': '/admin/notifications',
//         'icon': Icons.notifications,
//         'label': 'Notifications',
//       },
//       {'route': '/admin/reports', 'icon': Icons.report, 'label': 'Reports'},
//       {
//         'route': '/admin/moderation',
//         'icon': Icons.verified_user,
//         'label': 'Moderation',
//       },
//       {'route': '/admin/settings', 'icon': Icons.settings, 'label': 'Settings'},
//     ];

//     return Container(
//       width: 250,
//       color: Theme.of(context).colorScheme.surface,
//       child: Column(
//         children: [
//           const SizedBox(height: 20),
//           Text(
//             'Menu',
//             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//               color: Theme.of(context).colorScheme.primary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const Divider(),
//           Expanded(
//             child: ListView.builder(
//               itemCount: navItems.length,
//               itemBuilder: (context, index) {
//                 final item = navItems[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   child: ElevatedButton.icon(
//                     onPressed: () => Get.toNamed(item['route']! as String),
//                     icon: Icon(
//                       item['icon'] as IconData,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                     label: Text(
//                       item['label']! as String,
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Theme.of(context).colorScheme.surface,
//                       foregroundColor: Theme.of(context).colorScheme.primary,
//                       alignment: Alignment.centerLeft,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
