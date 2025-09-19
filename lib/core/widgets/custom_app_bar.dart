import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/profile/profile_screen.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/widgets/language_switcher.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isGuest;
  final Color? backgroundColor;
  final double? elevation;
  final bool showWelcomeAnimation;

  const CustomAppBar({
    super.key,
    required this.isGuest,
    this.backgroundColor,
    this.elevation,
    this.showWelcomeAnimation = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for notification badge
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final notificationController =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : Get.put(NotificationController());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final user = authController.currentUser.value;
      final isLoggedIn = authController.isLoggedIn;
      final imageUrl = user?.profileImageUrl ?? '';

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                widget.backgroundColor != null
                    ? [widget.backgroundColor!, widget.backgroundColor!]
                    : isDark
                    ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.95),
                    ]
                    : [
                      theme.colorScheme.surface,
                      theme.colorScheme.primaryContainer.withOpacity(0.1),
                    ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildMainContent(
              theme,
              user,
              isLoggedIn,
              imageUrl,
              notificationController,
              isDark,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainContent(
    ThemeData theme,
    dynamic user,
    bool isLoggedIn,
    String imageUrl,
    NotificationController notificationController,
    bool isDark,
  ) {
    return Row(
      children: [
        // Left side - User info
        Expanded(
          child:
              isLoggedIn && user != null
                  ? _buildUserSection(theme, user, imageUrl)
                  : _buildGuestSection(theme, isDark),
        ),

        const SizedBox(width: 16),

        // Right side - Actions
        _buildActionsSection(theme, isLoggedIn, notificationController, isDark),
      ],
    );
  }

  Widget _buildUserSection(ThemeData theme, dynamic user, String imageUrl) {
    final profileImage =
        imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : AssetImage(AssetPaths.guestImage) as ImageProvider;

    return GestureDetector(
      onTap: () => Get.to(() => ProfileScreen()),
      child: FadeInLeft(
        duration: const Duration(milliseconds: 600),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Enhanced avatar with status indicator
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: profileImage,
                    ),
                  ),
                  // Online status indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // User info with animation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'hi_user'.trArgs([user.fullName.toString()]),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestSection(ThemeData theme, bool isDark) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.grey[400]!, Colors.grey[300]!],
                ),
              ),
              child: Icon(Icons.person_outline, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'welcome'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'guest_user'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(
    ThemeData theme,
    bool isLoggedIn,
    NotificationController notificationController,
    bool isDark,
  ) {
    return FadeInRight(
      duration: const Duration(milliseconds: 600),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notifications we
          SlideInDown(
            delay: const Duration(milliseconds: 400),
            child: _buildNotificationButton(
              theme,
              isLoggedIn,
              notificationController,
            ),
          ),

          const SizedBox(width: 8),

          // Language switcher
          SlideInDown(
            delay: const Duration(milliseconds: 600),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: const LanguageSwitcher(
                backgroundColor: Colors.transparent,
                showLabel: false,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Login/Profile button
          if (!isLoggedIn)
            SlideInDown(
              delay: const Duration(milliseconds: 800),
              child: _buildLoginButton(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 22,
          color: iconColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
    ThemeData theme,
    bool isLoggedIn,
    NotificationController notificationController,
  ) {
    return GestureDetector(
      onTap: () {
        if (isLoggedIn) {
          Get.toNamed('/notifications');
        } else {
          PopupService.info('login_required'.tr, title: 'info'.tr);
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isLoggedIn ? Icons.notifications : Icons.notifications_none,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ),

          // Enhanced notification badge
          if (isLoggedIn && notificationController.unreadNotificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${notificationController.unreadNotificationCount > 9 ? '9+' : notificationController.unreadNotificationCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return GestureDetector(
      onTap: () => Get.to(() => const LoginScreen()),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 18, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 6),
            Text(
              'login'.tr,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension for minimum width container
extension MinWidthContainer on Widget {
  Widget get min => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 18),
    child: this,
  );
}
