import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/features/ai_chat/presentation/screens/ai_chat_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/chat/live_chat/farmer_chat_screen.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/screens/add_crop_screen.dart';
import 'package:krishi_link/features/farmer/screens/crop_detail_screen.dart';
import 'package:krishi_link/features/farmer/screens/farmer_menu.dart';
import 'package:krishi_link/features/farmer/widgets/crop_card.dart';
import 'package:krishi_link/features/farmer/widgets/tips_banner.dart';
import 'package:krishi_link/features/weather/controller/weather_controller.dart';
import 'package:krishi_link/features/weather/page/weather_details_page.dart';
import 'package:krishi_link/features/weather/weather_widget.dart';
import 'package:krishi_link/core/widgets/custom_app_bar.dart';
import 'package:krishi_link/src/features/notification/presentation/controllers/notification_controller.dart';

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
          // FloatingActionButton(
          //   heroTag: 'farmer_go_live',
          //   onPressed: () {
          //     final user = authController.currentUser.value;
          //     if (user != null) {
          //       // use the dignal r and go to the chat screen for the farmer where they receive the emessage fron the buyer for their prodcut , in that  pga emak aa button for the
          //       //// for the go live option so that th pressing it will make the uesr know the farmer
          //       Get.to(
          //         () => FarmerChatScreen(
          //           productId: '',
          //           productName: 'My Customers',
          //         ),
          //       );
          //     } else {
          //       PopupService.error('User not logged in');
          //     }

          //     /// working flow for the farmer live chat ,
          //     /// / baseurl/chathub it is hide becaseu for the signar r
          //     ///   it helps to conec to the chat hub it is the api of the singal r , for the suatheroiszed usedr so send the toke ,m
          //     ///  farmer pressed the  go live,  ,=> chathub
          //     ///  it willupdate the database and say the farmer is live ,
          //     ///  then buyer see the farmer is online buyer will press chat with farmer ,
          //     ///  then it will go to the chat hub and it will send the message to the farmer
          //     ///  / ofr the buyer it is alos need the / chathub  .
          //     ///  then it will go to the chat hub and it will send the message to the farmer
          //     ///  then after the buyer sends a message, it will be received by the farmer after they invoke the api get farmer id by product id ,{prodcut id }
          //     /// then it will go to the chat hub and it will send the message to the farmer
          //     /// then the farmer will receive the message and they can reply to the buyer
          //     ///  only if the buyer use that getFarmerIdByProductId method then only the buyer can chat with the farmer
          //     ///   then the farmer will receive the message and they can reply to the buyer . then theri is the api getmycustomerforchat becaue there are many customers, it
          //     ///
          //     ///
          //     ///  buyer get the farmer id , and for the farmer too ..
          //     ///  farmer get the buyer id
          //     ///  only after the farmer press that user then the gethcathistory api load , .
          //     ///  for the buyer it load fasly becasue it is  talking t o the farme one at the time   {get hcat history is sue for both  , farmer will add the buyer id , and buyer will add the farmer id }
          //     ///
          //     ///
          //     ///
          //     /// /// hub -> sendMessage this  mehtod i sin the backend  ,  to send the message or chat , toke for th authorization
          //   },
          //   backgroundColor: const Color.fromARGB(255, 231, 228, 236),
          //   tooltip: 'farmer go live'.tr,

          //   child: const Icon(
          //     Icons.local_convenience_store_sharp,
          //     color: Colors.black,
          //   ),
          // ),
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
