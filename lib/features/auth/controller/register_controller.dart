import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class RegisterController extends GetxController {
  // Text Controllers
  final fullNameController = TextEditingController();
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Reactive States
  final RxString inputMethod = 'email'.obs; // 'email' or 'phone'
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString role = 'buyer'.obs; // Default role

  // Device ID
  String? deviceId;

  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    initDeviceId();
  }

  /// Get unique device ID
  Future<void> initDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id; // or androidId
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
  }

  /// Detect if input is email or phone
  void detectInputMethod(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[9876]\d{9}$');

    if (emailRegex.hasMatch(value.trim())) {
      inputMethod.value = 'email';
    } else if (phoneRegex.hasMatch(value.trim())) {
      inputMethod.value = 'phone';
    } else {
      inputMethod.value = 'email'; // Default fallback
    }
  }

  /// Register user
  Future<void> register() async {
    if (!_validateInputs()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Prepare registration parameters
      final fullName = fullNameController.text.trim();
      final input = emailOrPhoneController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();
      final userRole = role.value;
      final devId = deviceId ?? '';
      File? image;
      double? latitude;
      double? longitude;

      // Detect if input is email or phone
      String email = '';
      String phone = '';
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final phoneRegex = RegExp(r'^[9876]\d{9}$');
      if (emailRegex.hasMatch(input)) {
        email = input;
      } else if (phoneRegex.hasMatch(input)) {
        phone = input;
      }

      final response = await _apiService.registerUser(
        fullName: fullName,
        password: password,
        confirmPassword: confirmPassword,
        role: userRole,
        deviceId: devId,
        email: email,
        phoneNumber: phone,
        latitude: latitude,
        longitude: longitude,
        image: image,
      );

      if (response['success'] == true || response['status'] == 201) {
        PopupService.success(
          'Registration successful! Please check your email to verify your account.',
          title: 'Success',
        );
        Get.offNamed('/login');
      } else {
        // Try to extract detailed error messages
        String errorMsg = response['message'] ?? 'Registration failed';
        if (response['errors'] != null) {
          if (response['errors'] is List) {
            errorMsg = (response['errors'] as List).join('\n');
          } else if (response['errors'] is Map) {
            errorMsg = (response['errors'] as Map).values
                .map((e) => e.toString())
                .join('\n');
          }
        }
        errorMessage.value = errorMsg;
        debugPrint('Registration error: $errorMsg');
        PopupService.error(errorMessage.value);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        debugPrint('Registration DioException data: $data');
        if (data is Map<String, dynamic>) {
          if (data['errors'] != null) {
            if (data['errors'] is Map) {
              errorMsg = (data['errors'] as Map).values
                  .expand((v) => v is List ? v : [v])
                  .join('\n');
            } else if (data['errors'] is List) {
              errorMsg = (data['errors'] as List).join('\n');
            }
          } else if (data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        }
      }
      errorMessage.value = errorMsg;
      debugPrint('Registration    exception: $errorMsg');
      PopupService.error(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate form inputs
  bool _validateInputs() {
    if (fullNameController.text.trim().isEmpty) {
      errorMessage.value = 'Full name is required';
      return false;
    }

    final input = emailOrPhoneController.text.trim();
    if (input.isEmpty) {
      errorMessage.value = 'Email or phone number is required';
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[9876]\d{9}$');

    if (!emailRegex.hasMatch(input) && !phoneRegex.hasMatch(input)) {
      errorMessage.value = 'Enter a valid email or phone number';
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      errorMessage.value = 'Password is required';
      return false;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      errorMessage.value = 'Passwords do not match';
      return false;
    }

    if (role.value.isEmpty) {
      errorMessage.value = 'User role is required';
      return false;
    }

    return true;
  }

  /// Dispose all text controllers
  @override
  void onClose() {
    fullNameController.dispose();
    emailOrPhoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
