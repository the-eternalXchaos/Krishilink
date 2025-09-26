import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller_new.dart';

class ProfileController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final RxBool isLoading = false.obs;
  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString? gender = ''.obs;
  final Rx<File?> profileImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    initializeFields();
  }

  void initializeFields() {
    final user = authController.currentUser.value;
    fullName.value = user?.fullName ?? '';
    email.value = user?.email ?? '';
    phoneNumber.value = user?.phoneNumber ?? '';
    gender?.value =
        StringExtension(user?.gender)?.capitalizeFirst ?? 'Rather not say';
  }

  Future<void> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        profileImage.value = File(result.files.single.path!);
        PopupService.success('Image selected successfully');
      }
    } catch (e) {
      PopupService.error('Failed to select image: ${e.toString().trim()}');
    }
  }

  Future<void> updateProfile() async {
    if (fullName.value.isEmpty ||
        email.value.isEmpty ||
        phoneNumber.value.isEmpty ||
        gender?.value == null) {
      PopupService.warning('All required fields must be filled');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.value)) {
      PopupService.error('Invalid email format');
      return;
    }

    isLoading.value = true;
    try {
      await authController.updateProfile(
        fullName: fullName.value,
        email: email.value,
        phoneNumber: phoneNumber.value,
        gender: gender?.value.toLowerCase() ?? 'Rather Not To Say',
        profileImage: profileImage.value,
      );
      Get.back();
      PopupService.success('Profile updated successfully');
    } catch (e) {
      PopupService.error('Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setGender(String? value) {
    gender?.value = value!;
  }
}

extension StringExtension on String {
  String get capitalizeFirst =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
