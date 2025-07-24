// Created by: Sandeep Wagle

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'package:krishi_link/core/controllers/language_controller.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
import 'package:krishi_link/widgets/language_switcher.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final controller = Get.find<AuthController>();
    final isGuest = !(controller.isLoggedIn);

    return Container(
      width: double.infinity,
      height: double.infinity, // This ensures full screen gradient
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDEFEF),
            Color.fromARGB(255, 179, 218, 179),
            Color.fromARGB(255, 179, 218, 179),
            Color(0xFFFDEFEF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Important to show gradient!
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                // Language Switcher Row
                GetBuilder<LanguageController>(
                  init: Get.find<LanguageController>(),
                  builder:
                      (langController) => Align(
                        alignment: Alignment.topRight,
                        child: const LanguageSwitcher(),
                      ),
                ),

                const SizedBox(height: 30),

                // Logo
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Image.asset(
                    krishilinkLogo,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 30),

                // Welcome Title
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  child: Text(
                    'welcome_headline'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                ),

                const SizedBox(height: 20),

                // Subtitle
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'welcome_subtitle'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Discover Products Button
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_bag),
                      label: Text('discover_products'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE05F34),
                        foregroundColor: Colors.white,
                        elevation: 12,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Get.offAll(() => BuyerHomePage(isGuest: isGuest));
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(thickness: 1),
                const SizedBox(height: 30),

                // Join With Us Button
                FadeInUp(
                  delay: const Duration(milliseconds: 900),
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text('join_with_us'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 14,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Get.toNamed('/login');
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tagline
                FadeIn(
                  delay: const Duration(milliseconds: 1200),
                  child: Text(
                    'explore_fresh_products_from_local_farmers'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
