import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class MockLoginScreen extends StatelessWidget {
  const MockLoginScreen({super.key});

  Future<void> _mockFarmerLogin() async {
    final AuthController authController = Get.find<AuthController>();
    try {
      await authController.saveAuthData(
        {
              'token': 'mock_farmer_token',
              'refreshToken': 'mock_refresh_token',
              'expiration':
                  DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'uid': 'farmer123',
              'fullName': 'Ram Bahadur',
              'email': 'ram@krishilink.com',
              'phoneNumber': '9841234567',
              'role': 'farmer',
              'address': 'Kathmandu, Nepal',
              'profileImageUrl': '',
            }
            as UserModel,
      );
      authController.navigateBasedOnRole();
      PopupService.success('Mock login successful!');
    } catch (e) {
      PopupService.error('Mock login failed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInUp(
                  child: Text(
                    'app_name'.tr,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Bypass Login (API Offline)',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _mockFarmerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: Text(
                              '${'login'.tr} as ${'farmer'.tr.capitalize!}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
