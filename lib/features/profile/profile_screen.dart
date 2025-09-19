import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/profile/profile_edit.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/src/core/constants/constants.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.find<AuthController>();

  void _logout(BuildContext context) {
    authController.logout();
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final isLoggedIn = authController.isLoggedIn;
        final userData = authController.currentUser.value;

        if (!isLoggedIn) {
          return _buildGuestView(context);
        }

        final imageUrl = userData?.profileImageUrl ?? '';
        final profileImage =
            imageUrl.isNotEmpty
                ? FadeInImage.assetNetwork(
                  placeholder: AssetPaths.guestImage,
                  image: imageUrl,
                  fit: BoxFit.cover,
                ).image
                : AssetImage(AssetPaths.guestImage);

        final formattedDate =
            userData?.createdAt != null
                ? DateFormat.yMMMMd().format(userData!.createdAt!)
                : 'not_available'.tr;

        return RefreshIndicator(
          onRefresh: () async => await authController.fetchUser(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                floating: false,
                pinned: true,
                title: Text(
                  userData?.fullName ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: MediaQuery.of(context).size.width / 2 - 60,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'profile-image',
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: profileImage,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => Get.to(() => const ProfileEdit()),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile_information'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData?.fullName ?? 'not_set'.tr,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        StringExtension(
                          userData?.role ?? 'unknown'.tr,
                        ).capitalizeFirst!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context: context,
                        children: [
                          _buildInfoRow(
                            context,
                            icon: Icons.email,
                            label: 'email'.tr,
                            value: userData?.email ?? 'not_set'.tr,
                          ),
                          _buildInfoRow(
                            context,
                            icon: Icons.phone,
                            label: 'phone'.tr,
                            value: userData?.phoneNumber ?? 'not_set'.tr,
                          ),
                          _buildInfoRow(
                            context,
                            icon: Icons.person_outline,
                            label: 'gender'.tr,
                            value:
                                StringExtension(
                                  userData?.gender ?? 'unknown'.tr,
                                ).capitalizeFirst!,
                          ),
                          _buildInfoRow(
                            context,
                            icon: Icons.calendar_today,
                            label: 'created_at'.tr,
                            value: formattedDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout),
                          label: Text('logout'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(205),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
                children
                    .asMap()
                    .entries
                    .map(
                      (entry) => Column(
                        children: [
                          entry.value,
                          if (entry.key < children.length - 1)
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withAlpha(50),
                              height: 24,
                            ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: ZoomIn(
        duration: const Duration(milliseconds: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(AssetPaths.guestImage),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            const SizedBox(height: 24),
            Text(
              'guest_user'.tr,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'please_login_to_view_profile'.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.offAll(() => const LoginScreen()),
              icon: const Icon(Icons.login),
              label: Text('login'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String? get capitalizeFirst =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
