import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/ai_chat/ai_chat_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/chat/models/message.dart';
import 'package:krishi_link/features/chat/screens/chat_list_screen.dart';
import 'package:krishi_link/features/farmer/screens/farmer_menu.dart';
import 'package:krishi_link/features/farmer/screens/add_crop_screen.dart';
import 'package:krishi_link/features/farmer/screens/crop_detail_screen.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/widgets/crop_card.dart';
import 'package:krishi_link/features/weather/controller/weather_controller.dart';
import 'package:krishi_link/features/weather/page/weather_details_page.dart';
import 'package:krishi_link/features/weather/weather_widget.dart';
import 'package:krishi_link/features/farmer/widgets/tips_banner.dart';
import 'package:krishi_link/widgets/custom_app_bar.dart';
import 'package:krishi_link/widgets/notification/notification_controller.dart';

// Placeholder for the new message screen (replace with your actual screen)

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  FarmerHomePageState createState() => FarmerHomePageState();
}

class FarmerHomePageState extends State<FarmerHomePage> {
  final WeatherController _weatherController =
      Get.isRegistered<WeatherController>()
          ? Get.find<WeatherController>()
          : Get.put(WeatherController());
  final FarmerController controller = Get.put(FarmerController());
  final NotificationController _notificationController = Get.put(
    NotificationController(),
  );
  final AuthController authController = Get.find<AuthController>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      controller.fetchCrops();
      _notificationController.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = [
      _buildHomeTab(),
      // const ChatListScreen(),
      _buildMyCropsTab(),
      const FarmerMenu(),
    ];

    return Scaffold(
      appBar: CustomAppBar(isGuest: authController.isLoggedIn),
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
            tooltip: 'scan_leaf_tooltip'.tr,
            child: Icon(Icons.camera_alt, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'chat_ai',
            onPressed: () {
              final user = authController.currentUser.value;
              if (user != null) {
                Get.to(() => AiChatScreen(name: user.fullName));
              } else {
                PopupService.error('User not logged in');
              }
            },
            backgroundColor: Colors.deepPurple,
            tooltip: 'chat_ai_tooltip'.tr,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          FloatingActionButton(
            heroTag: 'chat_ai',
            onPressed: () {
              final user = authController.currentUser.value;
              if (user != null) {
                Get.to(() => AiChatScreen(name: user.fullName));
              } else {
                PopupService.error('User not logged in');
              }
            },
            backgroundColor: const Color.fromARGB(255, 231, 228, 236),
            tooltip: 'chat_ai_tooltip'.tr,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home, semanticLabel: 'Home'),
            label: 'home'.tr,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.message, semanticLabel: 'Messages'),
          //   label: 'message'.tr,
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture, semanticLabel: 'My Crops'),
            label: 'my_crops'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, semanticLabel: 'Menu'),
            label: 'menu'.tr,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.chat, semanticLabel: 'New Message'),
          //   label: 'new_message'.tr, // New item
          // ),
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
          FadeInDown(
            child: GestureDetector(
              onTap: () {
                if (_weatherController.weather.value != null) {
                  Get.to(() => WeatherDetailsPage());
                } else {
                  PopupService.error('Weather data not loaded yet.');
                }
              },
              child: Obx(() {
                final weather = _weatherController.weather.value;
                return weather != null
                    ? WeatherWidget(weather: weather)
                    : const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
              }),
            ),
          ),
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
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.crops.length,
                      itemBuilder: (context, index) {
                        final crop = controller.crops[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CropCard(
                              crop: crop,
                              onTap:
                                  () => Get.to(
                                    () => CropDetailScreen(crop: crop),
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
                  icon: const Icon(Icons.add, semanticLabel: 'Add Crop'),
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
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.crops.length,
                      itemBuilder: (context, index) {
                        final crop = controller.crops[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: 100 * index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CropCard(
                              crop: crop,
                              onTap:
                                  () => Get.to(
                                    () => CropDetailScreen(crop: crop),
                                  ),
                              onEdit:
                                  () => Get.to(() => AddCropScreen(crop: crop)),
                              onDelete: () => controller.deleteCrop(crop.id),
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
}
