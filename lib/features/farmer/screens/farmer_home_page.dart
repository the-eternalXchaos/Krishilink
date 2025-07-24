import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/ai_chat/ai_chat_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/farmer/screens/farmer_menu.dart';
import 'package:krishi_link/features/farmer/screens/add_crop_screen.dart';
import 'package:krishi_link/features/farmer/screens/crop_detail_screen.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/widgets/crop_card.dart';
import 'package:krishi_link/features/farmer/widgets/weather_widget.dart';
import 'package:krishi_link/features/farmer/widgets/tips_banner.dart';
import 'package:krishi_link/widgets/custom_app_bar.dart';

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  FarmerHomePageState createState() => FarmerHomePageState();
}

class FarmerHomePageState extends State<FarmerHomePage> {
  final FarmerController controller = Get.put(FarmerController());
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;
  // late String location = authController.user.value.location;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      // final location =
      //     authController.currentUser.value?.address?.trimRight() ?? 'pokhara';
      // if (location.isNotEmpty) {
      //   controller.fetchWeather(location);
      // } else {
      //   debugPrint(' Location is empty');
      // }
      controller.fetchWeather(); // Default location, can be dynamic later

      controller.fetchCrops();
      controller.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [_buildHomeTab(), _buildMyCropsTab(), const FarmerMenu()];

    return Scaffold(
      appBar: CustomAppBar(isGuest: authController.isLoggedIn),

      // AppBar(
      //   title: Text('app_name'.tr),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.language),
      //       tooltip: 'language'.tr,
      //       onPressed: () {
      //         final currentLocale = Get.locale?.languageCode;
      //         if (currentLocale == 'en') {
      //           Get.updateLocale(const Locale('ne', 'NP'));
      //         } else {
      //           Get.updateLocale(const Locale('en', 'US'));
      //         }
      //       },
      //     ),
      //   ],
      //   backgroundColor: theme.colorScheme.primary,
      //   foregroundColor: theme.colorScheme.onPrimary,
      //   elevation: 0,
      // ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
                : pages[_currentIndex],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan_leaf',
            onPressed: () => Get.toNamed('/disease-detection'),
            backgroundColor: theme.colorScheme.primary,
            tooltip: 'scan_leaf_tooltip',
            child: Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'chat_ai',
            onPressed:
                () => Get.to(
                  () => AiChatScreen(
                    name: authController.currentUser.value!.fullName,
                  ),
                ),
            backgroundColor: Colors.deepPurple,
            tooltip: 'Chat with AI',
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        backgroundColor: theme.colorScheme.surface,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'.tr),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'my_crops'.tr,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'menu'.tr),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(child: WeatherWidget()),
          const SizedBox(height: 16),
          FadeInUp(child: TipsBanner()),
          const SizedBox(height: 16),
          Text(
            'your_crops'.tr,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Obx(
            () =>
                controller.crops.isEmpty
                    ? FadeInUp(
                      child: Center(
                        child: Text(
                          'no_crops_added'.tr,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                    : Column(
                      children:
                          controller.crops
                              .asMap()
                              .entries
                              .map(
                                (entry) => FadeInUp(
                                  delay: Duration(
                                    milliseconds: 100 * entry.key,
                                  ),
                                  child: CropCard(
                                    crop: entry.value,
                                    onTap:
                                        () => Get.to(
                                          () => CropDetailScreen(
                                            crop: entry.value,
                                          ),
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCropsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'my_crops'.tr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => AddCropScreen()),
                  icon: const Icon(Icons.add),
                  label: Text('add_crop'.tr),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () =>
                controller.crops.isEmpty
                    ? FadeInUp(
                      child: Center(
                        child: Text(
                          'no_crops_added'.tr,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                    : Column(
                      children:
                          controller.crops
                              .asMap()
                              .entries
                              .map(
                                (entry) => FadeInUp(
                                  delay: Duration(
                                    milliseconds: 100 * entry.key,
                                  ),
                                  child: CropCard(
                                    crop: entry.value,
                                    onTap:
                                        () => Get.to(
                                          () => CropDetailScreen(
                                            crop: entry.value,
                                          ),
                                        ),
                                    onEdit:
                                        () => Get.to(
                                          () =>
                                              AddCropScreen(crop: entry.value),
                                        ),
                                    onDelete:
                                        () => controller.deleteCrop(
                                          entry.value.id,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
        ],
      ),
    );
  }
}
