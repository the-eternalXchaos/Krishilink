import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/controllers/settings_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class UnifiedSettingsPage extends StatelessWidget {
  const UnifiedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.put(SettingsController());
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final role = authController.currentUser.value?.role ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => PopupService.info('${'app_name'.tr} v1.0.0'),
          ),
        ],
      ),
      body: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Profile Section
              _buildSection(
                title: 'profile_account'.tr,
                child: Column(
                  children: [
                    _buildProfileTile(context, authController),
                    const Divider(),
                    _buildSettingTile(
                      leading: const Icon(Icons.edit),
                      title: Text('edit_profile'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/profile/edit'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Notifications Section
              _buildSection(
                title: 'notifications'.tr,
                child: Column(
                  children: [
                    _buildNotificationToggle('order_updates'.tr, true.obs),
                    if (role == 'buyer')
                      _buildNotificationToggle('offers_deals'.tr, true.obs),
                    if (role == 'farmer')
                      _buildNotificationToggle('crop_alerts'.tr, true.obs),
                    if (role == 'admin')
                      _buildNotificationToggle('system_updates'.tr, true.obs),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Role-specific Settings
              if (role.isNotEmpty) _buildRoleSpecificSettings(role),
              const SizedBox(height: 16),
              // Privacy & Security Section
              _buildSection(
                title: 'privacy_security'.tr,
                child: Column(
                  children: [
                    _buildSettingTile(
                      leading: const Icon(Icons.password),
                      title: Text('change_password'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/settings/change-password'),
                    ),
                    _buildSettingTile(
                      leading: const Icon(Icons.security),
                      title: Text('two_step_verification'.tr),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'coming_soon'.tr,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      leading: const Icon(Icons.history),
                      title: Text('account_activity'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/settings/activity'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Help & Support Section
              _buildSection(
                title: 'help_support'.tr,
                child: Column(
                  children: [
                    _buildSettingTile(
                      leading: const Icon(Icons.contact_support),
                      title: Text('contact_us'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/support/contact'),
                    ),
                    _buildSettingTile(
                      leading: const Icon(Icons.description),
                      title: Text('terms_conditions'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/legal/terms'),
                    ),
                    _buildSettingTile(
                      leading: const Icon(Icons.info),
                      title: Text('about_app'.tr),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Get.toNamed('/about'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Language Section
              _buildSection(
                title: 'language'.tr,
                child: _buildSettingTile(
                  leading: const Icon(Icons.language),
                  title: Text('app_language'.tr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settingsController.currentLanguage.value == 'en_US'
                            ? 'english'.tr
                            : 'nepali'.tr,
                        style: theme.textTheme.bodyLarge,
                      ),
                      Switch.adaptive(
                        value:
                            settingsController.currentLanguage.value == 'ne_NP',
                        onChanged: (_) => settingsController.toggleLanguage(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Theme Section
              _buildSection(
                title: 'display'.tr,
                child: _buildSettingTile(
                  leading: Icon(
                    settingsController.isDarkMode.value
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: Text('dark_mode'.tr),
                  trailing: Switch.adaptive(
                    value: settingsController.isDarkMode.value,
                    onChanged: (_) => settingsController.toggleTheme(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Logout Section
              _buildSection(
                title: 'account'.tr,
                child: _buildSettingTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text('logout'.tr),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _showLogoutDialog(context, authController),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(
    BuildContext context,
    AuthController controller,
  ) {
    return Get.defaultDialog(
      title: 'logout'.tr,
      middleText: 'confirm_logout'.tr,
      textConfirm: 'yes'.tr,
      textCancel: 'no'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.logout();
        Get.offAllNamed('/login');
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, AuthController controller) {
    final theme = Theme.of(context);
    final user = controller.currentUser.value;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
      ),
      title: Text(
        user?.fullName ?? 'guest_user'.tr,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.email ?? user?.phoneNumber ?? 'no_contact_info'.tr,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (user?.role ?? 'guest').toString().capitalizeFirst ?? 'guest'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required Widget leading,
    required Widget title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading,
      title: title,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildNotificationToggle(String title, RxBool value) {
    return _buildSettingTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(title),
      trailing: Obx(
        () => Switch.adaptive(
          value: value.value,
          onChanged: (newValue) => value.value = newValue,
        ),
      ),
    );
  }

  Widget _buildRoleSpecificSettings(String role) {
    return _buildSection(
      title: 'features'.tr,
      child: Column(
        children: [
          if (role == 'farmer') ...[
            _buildSettingTile(
              leading: const Icon(Icons.store),
              title: Text('manage_products'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/farmer/unified-product-management'),
            ),
            _buildSettingTile(
              leading: const Icon(Icons.analytics),
              title: Text('farm_stats'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/farmer/stats'),
            ),
          ] else if (role == 'buyer') ...[
            _buildSettingTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text('my_orders'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/buyer/orders'),
            ),
            _buildSettingTile(
              leading: const Icon(Icons.favorite),
              title: Text('saved_products'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/buyer/saved'),
            ),
          ] else if (role == 'admin') ...[
            _buildSettingTile(
              leading: const Icon(Icons.store),
              title: Text('manage_products'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/admin/products'),
            ),
            _buildSettingTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: Text('manage_users'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/admin/users'),
            ),
            _buildSettingTile(
              leading: const Icon(Icons.bar_chart),
              title: Text('site_analytics'.tr),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Get.toNamed('/admin/analytics'),
            ),
          ],
        ],
      ),
    );
  }
}
