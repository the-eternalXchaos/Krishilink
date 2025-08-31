import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/constants/constants.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';

import '../../../core/components/product/management/unified_product_management.dart';

class FarmerMenu extends StatelessWidget {
  const FarmerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              _buildMenuItem(
                Icons.settings,
                'settings'.tr,
                () => Get.toNamed('/settings'),
              ),
              const Divider(),
              _buildMenuItem(
                Icons.shopping_basket,
                'my_orders'.tr,
                () => Get.toNamed('/farmer-orders'),
              ),
              _buildMenuItem(
                Icons.store,
                'marketplace'.tr,
                () => Future.delayed(const Duration(milliseconds: 10), () {
                  Get.to(() => BuyerHomePage(isGuest: false));
                }),
              ),
              _buildMenuItem(
                Icons.precision_manufacturing_outlined,
                'product_management'.tr,
                () => Get.to(() => UnifiedProductManagement()),
              ),
              const Divider(),
              _buildMenuItem(
                Icons.help,
                'tutorials'.tr,
                () => Get.toNamed('/farmer-tutorials'),
              ),
              const Divider(),
              _buildMenuItem(Icons.logout, 'logout'.tr, () {
                authController.logout();
                Get.offAllNamed('/login');
              }),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
