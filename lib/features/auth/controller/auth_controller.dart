import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/exceptions/app_exception.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:krishi_link/services/device_service.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AuthController extends GetxController {
  final ApiService _apiService;

  // Reactive state
  final currentUser = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  AuthController() : _apiService = ApiService();

  bool get isLoggedIn => currentUser.value != null;
  UserModel? get userData => currentUser.value;

  @override
  void onInit() {
    super.onInit();
    checkLogin();
  }

  // Future<void> saveAuthData(response) async {
  //   debugPrint('💾 Saving auth data...');

  //   final data = response['data'] ?? {};
  //   // Fallbacks for id/uid, role, etc.
  //   final uid = data['uid'] ?? data['id'] ?? '';
  //   final role =
  //       data['role'] ??
  //       (data['user'] != null ? data['user']['role'] : null) ??
  //       '';
  //   final fullName =
  //       data['fullName'] ??
  //       (data['user'] != null ? data['user']['fullName'] : null) ??
  //       '';
  //   final email =
  //       data['email'] ??
  //       (data['user'] != null ? data['user']['email'] : null) ??
  //       '';
  //   final phoneNumber =
  //       data['phoneNumber'] ??
  //       (data['user'] != null ? data['user']['phoneNumber'] : null) ??
  //       '';
  //   final address =
  //       data['address'] ??
  //       (data['user'] != null ? data['user']['address'] : null) ??
  //       '';
  //   final profileImageUrl =
  //       data['profileImageUrl'] ??
  //       (data['user'] != null ? data['user']['profileImageUrl'] : null) ??
  //       '';
  //   final token = data['token'] ?? '';
  //   final refreshToken = data['refreshToken'] ?? '';
  //   final expiration = data['expiration'] ?? DateTime.now().toIso8601String();
  //   final deviceId = data['deviceId'] ?? data['device_id'] ?? '';

  //   await TokenService.saveTokens(
  //     accessToken: token,
  //     refreshToken: refreshToken,
  //     expiration: expiration,
  //   );

  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool('isLoggedIn', true);
  //   await prefs.setString('role', role);
  //   await prefs.setString('uid', uid);
  //   await prefs.setString('fullName', fullName);
  //   await prefs.setString('email', email);
  //   await prefs.setString('phoneNumber', phoneNumber);
  //   await prefs.setString('address', address);
  //   await prefs.setString('profileImageUrl', profileImageUrl);
  //   await prefs.setString(
  //     'deviceId',
  //     deviceId.isNotEmpty ? deviceId : (prefs.getString('deviceId') ?? ''),
  //   );

  //   currentUser.value = UserModel(
  //     uid: uid,
  //     fullName: fullName,
  //     email: email,
  //     phoneNumber: phoneNumber,
  //     role: role,
  //     address: address,
  //     profileImageUrl: profileImageUrl,
  //     token: token,
  //     deviceId: deviceId,
  //   );

  //   debugPrint('✅ Auth data saved successfully');
  //   debugPrint('Current user: ${currentUser.value}');
  // }

  // save auth data
  Future<void> saveAuthData(UserModel user) async {
    debugPrint('💾 Saving auth data...');

    await TokenService.saveTokens(
      accessToken: user.token ?? '',
      refreshToken: user.refreshToken ?? '',
      expiration: user.expiration ?? DateTime.now().toIso8601String(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('role', user.role);
    await prefs.setString('uid', user.id);
    await prefs.setString('fullName', user.fullName);
    await prefs.setString('email', user.email ?? 'krishilink@gmail.com');
    await prefs.setString('phoneNumber', user.phoneNumber ?? '9800000000');
    await prefs.setString('address', user.address ?? '');
    await prefs.setString('profileImageUrl', user.profileImageUrl ?? '');
    await prefs.setString('deviceId', user.deviceId.toString());

    currentUser.value = user;

    debugPrint('✅ Auth data saved successfully');
    debugPrint('Current user: ${currentUser.value}');
  }

  Future<void> checkLogin() async {
    debugPrint('🔍 Checking login status...');

    try {
      if (!await TokenService.hasTokens()) {
        debugPrint('❌ No tokens found — redirecting to welcome');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/welcome');
        });
        return;
      }

      if (await TokenService.isTokenExpired()) {
        debugPrint('⚠️ Token expired — attempting refresh');
        final refreshed = await TokenService.refreshAccessToken();
        if (!refreshed) {
          debugPrint('❌ Refresh failed — clearing tokens');
          await TokenService.clearTokens();
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          currentUser.value = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed('/login');
          });
          return;
        } else {
          debugPrint('✅ Token refreshed successfully');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      currentUser.value = UserModel(
        id: prefs.getString('uid') ?? '',
        fullName: prefs.getString('fullName') ?? '',
        email: prefs.getString('email'),
        phoneNumber: prefs.getString('phoneNumber') ?? '9800000000',
        role: prefs.getString('role') ?? '',
        address: prefs.getString('address'),
        profileImageUrl: prefs.getString('profileImageUrl'),
        token: await TokenService.getAccessToken(),
        deviceId: prefs.getString('deviceId') ?? '',
      );

      debugPrint('✅ User loaded: [32m${currentUser.value?.fullName}[0m');

      if (currentUser.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateBasedOnRole();
        });
      }
    } catch (e, stackTrace) {
      debugPrint('🔥 checkLogin() failed — redirecting to login');
      debugPrint('Error: $e');
      debugPrint(stackTrace.toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });
      // await performMockLogin(); // COMMENTED OUT - Mock login disabled as fallback
    }
  }

  // COMMENTED OUT - Mock login functionality disabled
  /*
  Future<void> performMockLogin() async {
    debugPrint('🤖 Performing mock login...');
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('role', 'admin');
    await prefs.setString('uid', 'admin1');
    await prefs.setString('fullName', 'Admin User');
    await prefs.setString('email', 'admin@krishilink.com');
    await prefs.setString('phoneNumber', '9800000000');
    await prefs.setString('address', 'Lekthnath');
    await prefs.setString('profileImageUrl', '');

    await TokenService.saveTokens(
      accessToken: 'mock_admin_token',
      refreshToken: 'mock_refresh_token',
      expiration: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    );

    currentUser.value = UserModel(
      id: 'admin1',
      fullName: 'Admin User dfsdfsdfsddddddddddddfsf',
      email: 'admin@krishilink.com',
      phoneNumber: '9811111111',
      role: 'farmer',
      address: 'Sainik',
      profileImageUrl: '',
      token: 'mock_admin_token',
      deviceId: 'SUPER_ADMIN',
    );

    debugPrint('✅ Mock user loaded: Admin User');
    navigateBasedOnRole();
  }
  */ // END OF COMMENTED OUT performMockLogin method

  void navigateBasedOnRole() {
    if (currentUser.value == null) {
      debugPrint('⚠️ navigateBasedOnRole called with null user');
      PopupService.error(
        'No user session found. Please login again.',
        title: "Session Error",
      );
      Get.offAllNamed('/login');
      return;
    }

    final role = currentUser.value!.role.toLowerCase();
    final route = switch (role) {
      'admin' => '/admin-dashboard',
      'farmer' => '/farmer-dashboard',
      'buyer' => '/buyer-dashboard',
      _ => '/welcome',
    };

    debugPrint('🚀 Navigating to $route for role: $role');

    final arguments = role == 'buyer' ? {'isGuest': false} : null;
    Get.offAllNamed(route, arguments: arguments);

    Future.delayed(const Duration(milliseconds: 2 /*300 */), () {
      final title = switch (role) {
        'admin' => 'Welcome Admin',
        'farmer' => 'Welcome Farmer',
        'buyer' => 'Welcome Buyer',
        _ => 'Welcome to KrishiLink',
      };

      PopupService.success(
        'You are logged in as ${role.capitalize}',
        title: title,
      );
    });
  }

  Future<void> passwordLogin(String emailOrPhone, String password) async {
    try {
      isLoading(true);

      final deviceId = await DeviceService().getDeviceId(); // ✅ Only once
      debugPrint("🔐 Attempting password login");
      debugPrint(
        "   Email/Phone: $emailOrPhone , Password: $password, Device Id: $deviceId",
      );

      final url = Uri.parse(ApiConstants.passwordLoginEndpoint);
      debugPrint("🌐 API URL: $url");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'EmailorPhone': emailOrPhone,
          'Password': password,
          'DeviceId': deviceId,
        },
      );

      debugPrint("📥 Response received (${response.statusCode})");

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint("📥 Response body: ${response.body}");

        if (jsonResponse == null || jsonResponse.isEmpty) {
          throw AppException('No data received from server');
        }

        final data = jsonResponse['data'];
        if (data == null || data['token'] == null) {
          throw AppException('Authentication token not found in response');
        }

        final user = UserModel(
          id: data['id'] ?? '',
          fullName: data['fullName'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          role: data['role'] ?? '',
          address: data['address'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
          token: data['token'] ?? '',
          refreshToken: data['refreshToken'] ?? '',
          expiration: data['expiration'] ?? '',
          deviceId: deviceId,
        );

        await saveAuthData(user);
        navigateBasedOnRole();
      } else {
        _handleErrorResponse(response);
      }
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      debugPrint('$e');
      _showError('Login failed: $e');
    } finally {
      isLoading(false);
    }
  }

  /// ✅ Helper to extract error messages cleanly
  void _handleErrorResponse(http.Response response) {
    debugPrint("❌ Error response: ${response.body}");
    try {
      final error = jsonDecode(response.body);
      String errorMessage = 'Login failed';

      if (error['errors'] != null && error['errors'] is Map) {
        final errors = error['errors'] as Map;
        if (errors['MyError'] != null && errors['MyError'] is List) {
          final myErrors = errors['MyError'] as List;
          if (myErrors.isNotEmpty) {
            errorMessage = myErrors.first.toString();
          }
        }
      } else if (error['message'] != null) {
        errorMessage = error['message'];
      }

      throw AppException(errorMessage);
    } catch (_) {
      throw AppException('Unexpected server error');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      // Must initialize once in your app (e.g. in main())
      await GoogleSignIn.instance.initialize(
        clientId: "<YOUR_CLIENT_ID>.apps.googleusercontent.com",
      );

      // Interactive login
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email'],
      );

      final auth = account.authentication;
      final idToken = auth.idToken; // ✅ send this to your backend

      if (idToken == null) throw Exception("No ID token received");

      final user = await _apiService.loginWithGoogle(idToken);
      await saveAuthData(user);
      navigateBasedOnRole();
    } catch (e) {
      _showError("Google login failed: $e");
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      isLoading(true);
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        throw AppException('Facebook login failed');
      }
      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null) {
        throw AppException('Facebook authentication failed');
      }
      final user = await _apiService.loginWithFacebook(accessToken);
      await saveAuthData(user.toJson() as UserModel);
      navigateBasedOnRole();
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Facebook login failed: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> loginWithApple() async {
    try {
      isLoading(true);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final user = await _apiService.loginWithApple(
        identityToken: credential.identityToken!,
        authorizationCode: credential.authorizationCode,
      );
      await saveAuthData(user.toJson() as UserModel);
      navigateBasedOnRole();
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Apple login failed: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await TokenService.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      currentUser.value = null;

      Get.offAllNamed('/welcome');
      PopupService.success(
        'You have been logged out successfully.',
        title: 'Logout Successful',
      );
    } catch (e) {
      _showError('Logout failed: $e');
    }
  }

  Future<void> sendOtp(String identifier) async {
    try {
      isLoading(true);
      debugPrint('[OTP] Attempting to send OTP to: $identifier');

      final prefs = await SharedPreferences.getInstance();
      final deviceId =
          prefs.getString('deviceId') ?? (await DeviceService().getDeviceId());

      final response = await _apiService.sendOtp(identifier, deviceId);
      debugPrint('[OTP] Response: $response');

      final isSuccess =
          response['statusCode'] == 200 ||
          (response['message']?.toLowerCase().contains('OTP sent') ?? false);

      if (isSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed(
            '/otp-verify',
            arguments: {'identifier': identifier, 'deviceId': deviceId},
          );
        });
      } else {
        PopupService.error(
          'Failed to Send OTP\nTry again later',
          title: 'Error',
        );
      }
    } on AppException catch (e) {
      debugPrint('[OTP] AppException: ${e.message}');
      _showError('Something went wrong: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[OTP] Unexpected error: $e');
      debugPrint(stackTrace.toString());
      _showError('Failed to send OTP. Please try again.');
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> verifyOtp(String identifier, String otp) async {
    try {
      isLoading(true);
      debugPrint('[AuthController] Verifying OTP for: $identifier');

      final prefs = await SharedPreferences.getInstance();
      final deviceId =
          prefs.getString('deviceId') ?? (await DeviceService().getDeviceId());

      final user = await _apiService.verifyOtp(
        otp: otp,
        identifier: identifier,
        deviceId: deviceId,
      );

      debugPrint('[AuthController] User data: ${user.toJson()}');

      await saveAuthData(user); // ✅ pass model directly
      navigateBasedOnRole();

      PopupService.success('Welcome back!', title: 'Login Successful');
    } on AppException catch (e) {
      debugPrint(e.toString());
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
    } finally {
      isLoading(false);
    }
  }

  void _showError(String message) {
    final normalized = message.toLowerCase();

    final displayMessage =
        normalized.contains('formatexception') ||
                normalized.contains('user not found') ||
                normalized.contains('no user record') ||
                normalized.contains('user does not exist')
            ? 'user_not_found'.tr
            : normalized.contains('user is not registrerd') ||
                normalized.contains('user is not registered') ||
                normalized.contains(
                  'not registrerd with the provided information',
                )
            ? 'user_not_registered'.tr
            : normalized.contains('wrong password') ||
                normalized.contains('incorrect password')
            ? 'incorrect_password'.tr
            : normalized.contains('invalid credentials') ||
                normalized.contains('invalid username') ||
                normalized.contains('invalid password')
            ? 'invalid_credentials'.tr
            : normalized.contains('network') ||
                normalized.contains('socket') ||
                normalized.contains('503') // Add 503 error code check
            ? 'network_error'.tr
            : normalized.contains('500') || normalized.contains('server error')
            ? 'server_error'.tr
            : 'something_went_wrong'.tr;

    errorMessage.value = displayMessage;
    debugPrint('Login Error: $displayMessage');

    PopupService.error(displayMessage, title: 'login_failed'.tr);
  }

  Future<void> fetchUser() async {}

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? gender,
    File? profileImage,
  }) async {}

  Future<void> signInWithGoogle() async {}

  Future<void> signInWithFacebook() async {}

  Future<void> signInWithApple() async {}

  // // Farmer Live Status
  // final RxMap<String, bool> _farmerLiveStatus = <String, bool>{}.obs;
  // // in authController
  // Timer? _liveStatusTimer;

  // void startFarmerLivePolling(String productId) {
  //   _liveStatusTimer?.cancel();
  //   _liveStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
  //     fetchFarmerLiveStatus(productId);
  //   });
  // }

  // void stopPolling() {
  //   _liveStatusTimer?.cancel();
  // }

  // bool isFarmerLive(String productId) => _farmerLiveStatus[productId] ?? false;
  // Future<void> fetchFarmerLiveStatus(String productId) async {
  //   final status = await _apiService.isFarmerLive(productId);
  //   _farmerLiveStatus[productId] = status;
  // }
}
