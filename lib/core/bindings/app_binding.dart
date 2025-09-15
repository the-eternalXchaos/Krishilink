import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/controllers/language_controller.dart';
import 'package:krishi_link/core/controllers/settings_controller.dart';
import 'package:krishi_link/controllers/profile_controller.dart';
import 'package:krishi_link/src/core/services/connectivity_service.dart';

/// Global app binding - initializes controllers needed throughout the app
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Global controllers - permanent throughout app lifecycle
    Get.put(AuthController(), permanent: true);
    Get.put(LanguageController(), permanent: true);
    Get.put(ConnectivityService(), permanent: true);

    // Re-creatable global controllers
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
  }
}
