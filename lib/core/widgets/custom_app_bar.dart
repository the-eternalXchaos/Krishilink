import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/profile/profile_screen.dart';
import 'package:krishi_link/widgets/language_switcher.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isGuest;

  const CustomAppBar({super.key, required this.isGuest});

  @override
  Size get preferredSize => const Size.fromHeight(72.0);

  @override
  Widget build(BuildContext context) {
    final authController =
        Get.isRegistered()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final notificationController =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());

    final theme = Theme.of(context);

    return Obx(() {
      final user = authController.currentUser.value;
      final isLoggedIn = authController.isLoggedIn;
      final imageUrl = user?.profileImageUrl ?? '';
      final profileImage =
          imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : AssetImage(guestImage) as ImageProvider;

      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            children: [
              if (isLoggedIn && user != null) ...[
                GestureDetector(
                  onTap: () => Get.to(() => ProfileScreen()),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: profileImage),
                      const SizedBox(width: 8),
                      SizedBox(
                        // width: Get.width / 3.5,
                        width: 150,
                        child: Text(
                          'hi_user'.trArgs([user.fullName]),
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_rounded,
                            size: iconSize,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            Get.toNamed('/notifications');
                          },
                        ),
                        if (notificationController.unreadNotificationCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${notificationController.unreadNotificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const LanguageSwitcher(backgroundColor: Colors.transparent),
                  ],
                ),
              ] else ...[
                Icon(Icons.person, size: 40, color: Colors.grey.shade600),
                const SizedBox(width: 10),
                Text('hi_guest'.tr, style: theme.textTheme.titleLarge),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        PopupService.info(
                          'Custom app bar action',
                          title: 'Info',
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Get.to(() => const LoginScreen()),
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text('login'.tr),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/features/auth/screens/login_screen.dart';
// import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
// import 'package:krishi_link/features/profile/profile_screen.dart';
// import 'package:krishi_link/widgets/language_switcher.dart';

// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final bool isGuest;

//   const CustomAppBar({super.key, required this.isGuest});

//   @override
//   Size get preferredSize => const Size.fromHeight(72.0);

//   @override
//   Widget build(BuildContext context) {
//     final authController = Get.find<AuthController>();
//     // Initialize FarmerController only if user is not a guest
//     final farmerController =
//         isGuest
//             ? null
//             : Get.isRegistered<FarmerController>()
//             ? Get.find<FarmerController>()
//             : Get.put(FarmerController());

//     final theme = Theme.of(context);

//     return Obx(() {
//       final user = authController.currentUser.value;
//       final isLoggedIn = authController.isLoggedIn && !isGuest;
//       final imageUrl = user?.profileImageUrl ?? '';
//       final profileImage =
//           imageUrl.isNotEmpty
//               ? NetworkImage(imageUrl)
//               : AssetImage(guestImage) as ImageProvider;

//       return Container(
//         decoration: BoxDecoration(
//           color: theme.colorScheme.surface,
//           borderRadius: const BorderRadius.vertical(
//             bottom: Radius.circular(20),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withAlpha(30),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: SafeArea(
//           child: Row(
//             children: [
//               if (isLoggedIn && user != null) ...[
//                 GestureDetector(
//                   onTap: () => Get.to(() => ProfileScreen()),
//                   child: Row(
//                     children: [
//                       CircleAvatar(radius: 24, backgroundImage: profileImage),
//                       const SizedBox(width: 8),
//                       SizedBox(
//                         width: 150,
//                         child: Text(
//                           'hi_user'.trArgs([user.fullName]),
//                           style: theme.textTheme.titleSmall,
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Spacer(),
//                 Row(
//                   children: [
//                     Stack(
//                       children: [
//                         IconButton(
//                           icon: Icon(
//                             Icons.notifications_rounded,
//                             size: iconSize,
//                             color: theme.colorScheme.primary,
//                           ),
//                           onPressed: () {
//                             Get.toNamed('/notifications');
//                           },
//                         ),
//                         if (farmerController != null &&
//                             farmerController.unreadNotificationCount > 0)
//                           Positioned(
//                             right: 8,
//                             top: 8,
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: const BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Text(
//                                 '${farmerController.unreadNotificationCount}',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const LanguageSwitcher(backgroundColor: Colors.transparent),
//                   ],
//                 ),
//               ] else ...[
//                 Icon(Icons.person, size: 40, color: Colors.grey.shade600),
//                 const SizedBox(width: 10),
//                 Text('hi_guest'.tr, style: theme.textTheme.titleLarge),
//                 const Spacer(),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: Icon(
//                         Icons.notifications_none,
//                         color: theme.colorScheme.primary,
//                       ),
//                       onPressed: () {
//                         Get.snackbar(
//                           'login_required'.tr,
//                           'please_login_to_view_notifications'.tr,
//                         );
//                       },
//                     ),
//                     const SizedBox(width: 8),
//                     TextButton(
//                       onPressed: () => Get.to(() => const LoginScreen()),
//                       style: TextButton.styleFrom(
//                         backgroundColor: theme.colorScheme.primary,
//                         foregroundColor: theme.colorScheme.onPrimary,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                       ),
//                       child: Text('login'.tr),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }
