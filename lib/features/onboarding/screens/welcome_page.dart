// Created by: Sandeep Wagle
// Enhanced by: Assistant

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'package:krishi_link/core/controllers/language_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/widgets/language_switcher.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Floating animation for logo
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Pulse animation for buttons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final controller = Get.find<AuthController>();
    final isGuest = !(controller.isLoggedIn);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                    const Color(0xFF16213E),
                  ]
                  : [
                    const Color(0xFFFDEFEF),
                    const Color(0xFFE8F5E8),
                    const Color(0xFFD4F1D4),
                    const Color(0xFFFDEFEF),
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundDecorations(isDark),

              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // Language Switcher with enhanced styling
                    _buildLanguageSwitcher(),

                    const SizedBox(height: 40),

                    // Floating animated logo
                    _buildAnimatedLogo(),

                    const SizedBox(height: 40),

                    // Welcome content
                    _buildWelcomeContent(theme, isDark),

                    const SizedBox(height: 50),

                    // Action buttons
                    _buildActionButtons(theme, isGuest),

                    const SizedBox(height: 40),

                    // Features showcase
                    _buildFeaturesShowcase(theme, isDark),

                    const SizedBox(height: 30),

                    // Footer tagline
                    _buildFooterTagline(theme),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecorations(bool isDark) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -50,
          right: -50,
          child: FadeIn(
            duration: const Duration(seconds: 2),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.green[300] : Colors.green[200])
                    ?.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),

        // Bottom left circle
        Positioned(
          bottom: -80,
          left: -80,
          child: FadeIn(
            delay: const Duration(milliseconds: 500),
            duration: const Duration(seconds: 2),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.orange[300] : Colors.orange[200])
                    ?.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),

        // Middle floating elements
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: 20,
          child: SlideInRight(
            delay: const Duration(seconds: 1),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.eco, color: Colors.green[600], size: 30),
            ),
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          left: 30,
          child: SlideInLeft(
            delay: const Duration(milliseconds: 1200),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.agriculture,
                color: Colors.orange[600],
                size: 25,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSwitcher() {
    return GetBuilder<LanguageController>(
      init: Get.find<LanguageController>(),
      builder:
          (langController) => FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const LanguageSwitcher(),
              ),
            ),
          ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: FadeInDown(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                AssetPaths.krishilinkLogo,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Welcome Title with enhanced typography
        FadeInUp(
          duration: const Duration(milliseconds: 1000),
          child: ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [theme.primaryColor, Colors.green[700]!],
                ).createShader(bounds),
            child: Text(
              'welcome_headline'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Enhanced Subtitle
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(isDark ? 0.05 : 0.3),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'welcome_subtitle'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isGuest) {
    return Column(
      children: [
        // Discover Products Button with enhanced design
        FadeInUp(
          delay: const Duration(milliseconds: 600),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE05F34), Color(0xFFFF7A59)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE05F34).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                    label: Text(
                      'discover_products'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Get.offAll(() => BuyerHomePage(isGuest: isGuest));
                    },
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Stylish divider
        FadeIn(
          delay: const Duration(milliseconds: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Text(
                  'or'.tr,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Join With Us Button with enhanced design
        FadeInUp(
          delay: const Duration(milliseconds: 900),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 22),
              label: Text(
                'join_with_us'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Get.toNamed('/login');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesShowcase(ThemeData theme, bool isDark) {
    final features = [
      {
        'icon': Icons.verified_user,
        'title': 'verified_farmers'.tr,
        'color': Colors.green,
      },
      {
        'icon': Icons.local_shipping,
        'title': 'fast_delivery'.tr,
        'color': Colors.blue,
      },
      {
        'icon': Icons.eco,
        'title': 'organic_products'.tr,
        'color': Colors.orange,
      },
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 1100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(isDark ? 0.05 : 0.3),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              'why_choose_us'.tr,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.headlineSmall?.color,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    return SlideInUp(
                      delay: Duration(milliseconds: 1200 + (index * 200)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (feature['color'] as Color).withOpacity(
                                0.1,
                              ),
                            ),
                            child: Icon(
                              feature['icon'] as IconData,
                              color: feature['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            feature['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterTagline(ThemeData theme) {
    return FadeIn(
      delay: const Duration(milliseconds: 1500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'explore_fresh_products_from_local_farmers'.tr,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
