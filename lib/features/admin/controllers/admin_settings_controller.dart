// lib/features/admin/controller/admin_settings_controller.dart
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminSettingsController extends GetxController {
  final adminProfile = Rxn<UserModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminProfile();
  }

  Future<void> fetchAdminProfile() async {
    try {
      isLoading(true);
      // Mock; replace with API
      adminProfile.value = UserModel(
        id: 'admin1',
        fullName: 'Admin User',
        email: 'admin@krishilink.com',
        role: 'admin',
        deviceId: '',
      );
    } catch (e) {
      PopupService.error('Failed to load profile: $e');
    } finally {
      isLoading(false);
    }
  }
}
