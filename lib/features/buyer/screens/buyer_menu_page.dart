import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishi_link/core/components/confirm%20box/custom_confirm_dialog.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';

class BuyerMenuPage extends StatefulWidget {
  const BuyerMenuPage({super.key});

  @override
  State<BuyerMenuPage> createState() => _BuyerMenuPageState();
}

class _BuyerMenuPageState extends State<BuyerMenuPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Animation<double>>? _menuAnimations;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final role = authController.currentUser.value?.role.toLowerCase();
      final totalTiles = 5 + (role == 'farmer' ? 1 : 0);

      _menuAnimations = List.generate(
        totalTiles,
        (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.1 * index,
              0.4 + 0.1 * index,
              curve: Curves.easeOut,
            ),
          ),
        ),
      );

      _animationController.forward();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final userName = authController.currentUser.value?.fullName ?? 'guest'.tr;
      final imageUrl = authController.currentUser.value?.profileImageUrl;
      final role = authController.currentUser.value?.role ?? 'buyer'.tr;
      final isFarmer = role.toLowerCase() == 'farmer';

      if (_menuAnimations == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      int animationIndex = 0;

      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: Theme.of(context).appBarTheme.elevation ?? 0,
          centerTitle: true,
          title: Text(
            'menu'.tr,
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
        ),
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(
                  userName,
                  role,
                  imageUrl,
                  colorScheme,
                  textTheme,
                  _menuAnimations![animationIndex++],
                ),
                const SizedBox(height: 30),
                _buildMenuTile(
                  animationIndex: animationIndex++,
                  icon: Icons.shopping_bag,
                  label: 'my_orders'.tr,
                  onTap: () => Get.toNamed('/my-orders'),
                ),
                _buildMenuTile(
                  animationIndex: animationIndex++,
                  icon: Icons.favorite,
                  label: 'wishlist'.tr,
                  onTap: () => Get.toNamed('/wishlist'),
                ),
                if (isFarmer)
                  _buildMenuTile(
                    animationIndex: animationIndex++,
                    icon: Icons.agriculture,
                    label: 'my_products'.tr,
                    onTap: () => Get.toNamed('/product-management'),
                  ),
                _buildMenuTile(
                  animationIndex: animationIndex++,
                  icon: Icons.settings,
                  label: 'settings'.tr,
                  onTap: () => Get.toNamed('/settings'),
                ),
                _buildMenuTile(
                  animationIndex: animationIndex++,
                  icon: Icons.logout,
                  label: 'logout'.tr,
                  onTap:
                      () => Get.dialog(
                        CustomConfirmDialog(
                          title: 'logout'.tr,
                          content: 'are_you_sure_logout'.tr,
                          confirmText: 'confirm'.tr,
                          cancelText: 'cancel'.tr,
                          onConfirm: () {
                            authController.logout();
                            Get.back();
                          },
                          onCancel: Get.back,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProfileSection(
    String userName,
    String role,
    String? imageUrl,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Semantics(
            label: 'profile_image'.tr,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? '',
                  placeholder: (_, __) => const CircularProgressIndicator(),
                  errorWidget:
                      (_, __, ___) =>
                          Image.asset(guestImage, fit: BoxFit.cover),
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role.tr,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required int animationIndex,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _menuAnimations![animationIndex],
      builder: (context, child) {
        return FadeTransition(
          opacity: _menuAnimations![animationIndex],
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.9,
              end: 1.0,
            ).animate(_menuAnimations![animationIndex]),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(
            icon,
            color: isLogout ? colorScheme.error : colorScheme.primary,
            size: 24,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isLogout ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          tileColor: colorScheme.surface,
          splashColor: colorScheme.primary.withValues(alpha: 0.15),
          trailing: Icon(
            Icons.chevron_right,
            color:
                isLogout
                    ? colorScheme.error
                    : colorScheme.onSurface.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
      ),
    );
  }
}

//   void _showLogoutDialog(BuildContext context, AuthController authController) {
//     Get.dialog(
//       AlertDialog(
//         title: Text('logout'.tr),
//         content: Text('are_you_sure_logout'.tr),
//         actions: [
//           TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               authController.logout();
//             },
//             child: Text('confirm'.tr),
//           ),
//         ],
//       ),
//     );
//   }
// }
