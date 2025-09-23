// // This file is intentionally left blank. Use auth_controller.dart for all authentication logic.
// // / import 'package:animate_do/animate_do.dart';

// // BackInUp

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
//
// import 'package:krishi_link/core/utils/api_constants.dart';
// import 'package:krishi_link/exceptions/app_exception.dart';
// import 'package:krishi_link/features/admin/models/user_model.dart';
// import 'package:krishi_link/services/api_service.dart';
// import 'package:krishi_link/services/popup_service.dart';
//  import 'package:krishi_link/src/features/auth/data/token_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// class AuthController extends GetxController {
//   final ApiService _apiService;

//   // Reactive state
//   final currentUser = Rxn<UserModel>();
//   final isLoading = false.obs;
//   final errorMessage = RxnString();

//   AuthController() : _apiService = ApiService();

//   bool get isLoggedIn => currentUser.value != null;
//   UserModel? get userData => currentUser.value;

//   @override
//   void onInit() {
//     super.onInit();
//     checkLogin();
//   }

//   Future<void> saveAuthData(Map<String, dynamic> response) async {
//     debugPrint('💾 Saving auth data...');

//     await TokenService.saveTokens(
//       accessToken: response['token'] ?? '',
//       refreshToken: response['refreshToken'] ?? '',
//       expiration: response['expiration'] ?? DateTime.now().toIso8601String(),
//     );

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isLoggedIn', true);
//     await prefs.setString('role', response['role'] ?? '');
//     await prefs.setString('uid', response['uid'] ?? '');
//     await prefs.setString('fullName', response['fullName'] ?? '');
//     await prefs.setString('email', response['email'] ?? '');
//     await prefs.setString('phoneNumber', response['phoneNumber'] ?? '');
//     await prefs.setString('address', response['address'] ?? '');
//     await prefs.setString('profileImageUrl', response['profileImageUrl'] ?? '');

//     currentUser.value = UserModel(
//       uid: response['uid'] ?? '',
//       fullName: response['fullName'] ?? '',
//       email: response['email'],
//       phoneNumber: response['phoneNumber'],
//       role: response['role'] ?? '',
//       address: response['address'],
//       profileImageUrl: response['profileImageUrl'],
//       token: response['token'],
//     );

//     debugPrint('✅ Auth data saved successfully');
//   }

//   Future<void> checkLogin() async {
//     debugPrint('🔍 Checking login status...');

//     if (!await TokenService.hasTokens()) {
//       debugPrint('❌ No tokens found');
//       currentUser.value = null;
//       return;
//     }

//     if (await TokenService.isTokenExpired()) {
//       debugPrint('⚠️ Token expired');
//       await TokenService.clearTokens();
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       currentUser.value = null;
//       Get.offAllNamed('/login');
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     currentUser.value = UserModel(
//       uid: prefs.getString('uid') ?? '',
//       fullName: prefs.getString('fullName') ?? '',
//       email: prefs.getString('email'),
//       phoneNumber: prefs.getString('phoneNumber'),
//       role: prefs.getString('role') ?? '',
//       address: prefs.getString('address'),
//       profileImageUrl: prefs.getString('profileImageUrl'),
//       token: await TokenService.getAccessToken(),
//     );

//     debugPrint('✅ User loaded: ${currentUser.value?.fullName}');

//     if (currentUser.value != null) {
//       navigateBasedOnRole();
//     }
//   }

//   void navigateBasedOnRole() {
//     if (currentUser.value == null) {
//       debugPrint('⚠️ navigateBasedOnRole called with null user');
//       PopupService.show(
//         type: PopupType.error,
//         title: "Session Error",
//         message: "No user session found. Please login again.",
//         autoDismiss: true,
//       );
//       Get.offAllNamed('/login');
//       return;
//     }

//     final role = currentUser.value!.role.toLowerCase();
//     final route = switch (role) {
//       'admin' => '/admin-dashboard',
//       'farmer' => '/farmer-dashboard',
//       'buyer' => '/buyer-dashboard',
//       _ => '/welcome',
//     };

//     debugPrint('🚀 Navigating to $route for role: $role');

//     final arguments = role == 'buyer' ? {'isGuest': false} : null;
//     Get.offAllNamed(route, arguments: arguments);

//     Future.delayed(const Duration(milliseconds: 2 /*300 */), () {
//       final title = switch (role) {
//         'admin' => 'Welcome Admin',
//         'farmer' => 'Welcome Farmer',
//         'buyer' => 'Welcome Buyer',
//         _ => 'Welcome to KrishiLink',
//       };

//       PopupService.show(
//         type: PopupType.success,
//         title: title,
//         message: 'You are logged in as ${role.capitalize}',
//         autoDismiss: true,
//       );
//     });
//   }

//   Future<void> passwordLogin(String emailOrPhone, String password) async {
//     try {
//       isLoading(true);
//       debugPrint("🔐 Attempting password login");
//       debugPrint("   Email/Phone: $emailOrPhone");

//       final url = Uri.parse(ApiConstants.passwordLoginEndpoint);
//       debugPrint("🌐 API URL: $url");

//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//         body: {'EmailorPhone': emailOrPhone, 'Password': password},
//       );

//       debugPrint("📥 Response received (${response.statusCode})");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data == null || data.isEmpty) {
//           throw AppException('No data received from server');
//         }
//         if (data['token'] == null) {
//           throw AppException('Authentication token not found in response');
//         }
//         await saveAuthData(data);
//         // Pass Map directly
//         navigateBasedOnRole();
//       } else {
//         final error = jsonDecode(response.body);
//         throw AppException(error['message'] ?? 'Login failed');
//       }
//     } on AppException catch (e) {
//       _showError(e.message);
//     } catch (e) {
//       _showError('Login failed: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<void> loginWithGoogle() async {
//     try {
//       isLoading(true);
//       final googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) throw AppException('Google login cancelled');
//       final googleAuth = await googleUser.authentication;
//       final accessToken = googleAuth.accessToken;
//       if (accessToken == null) {
//         throw AppException('Google authentication failed');
//       }
//       final user = await _apiService.loginWithGoogle(accessToken);
//       await saveAuthData(user.toJson());

//       navigateBasedOnRole();
//     } on AppException catch (e) {
//       _showError(e.message);
//     } catch (e) {
//       _showError('Google login failed: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<void> loginWithFacebook() async {
//     try {
//       isLoading(true);
//       final result = await FacebookAuth.instance.login();
//       if (result.status != LoginStatus.success) {
//         throw AppException('Facebook login failed');
//       }
//       final accessToken = result.accessToken?.tokenString;
//       if (accessToken == null) {
//         throw AppException('Facebook authentication failed');
//       }
//       final user = await _apiService.loginWithFacebook(accessToken);
//       await saveAuthData(user.toJson());
//       navigateBasedOnRole();
//     } on AppException catch (e) {
//       _showError(e.message);
//     } catch (e) {
//       _showError('Facebook login failed: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<void> loginWithApple() async {
//     try {
//       isLoading(true);
//       final credential = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//       );
//       final user = await _apiService.loginWithApple(
//         identityToken: credential.identityToken!,
//         authorizationCode: credential.authorizationCode,
//       );
//       await saveAuthData(user.toJson());
//       navigateBasedOnRole();
//     } on AppException catch (e) {
//       _showError(e.message);
//     } catch (e) {
//       _showError('Apple login failed: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<void> registerUser(UserModel user, String password) async {
//     try {
//       isLoading(true);
//       final data = await _apiService.registerUser(
//         user: user,
//         password: password,
//       );
//       await saveAuthData(data);
//       navigateBasedOnRole();
//     } on AppException catch (e) {
//       _showError(e.message);
//     } catch (e) {
//       _showError('Registration failed: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   Future<void> logout() async {
//     try {
//       await TokenService.clearTokens();
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       currentUser.value = null;

//       Get.offAllNamed('/welcome');
//       PopupService.show(
//         type: PopupType.success,
//         title: 'Logout Successful',
//         message: 'You have been logged out successfully.',
//         autoDismiss: true,
//       );
//     } catch (e) {
//       _showError('Logout failed: $e');
//     }
//   }

//   // Future<void> sendOtp(String identifier) async {
//   //   try {
//   //     isLoading(true);
//   //     await _apiService.sendOtp(identifier);
//   //     PopupService.show(
//   //       type: PopupType.success,
//   //       title: 'OTP Sent',
//   //       message: 'An OTP has been sent to $identifier',
//   //       autoDismiss: true,
//   //     );
//   //   } on AppException catch (e) {
//   //     _showError(e.message);
//   //     rethrow;
//   //   } catch (e) {
//   //     _showError('Failed to send OTP: $e');
//   //     rethrow;
//   //   } finally {
//   //     isLoading(false);
//   //   }
//   // }
//   Future<void> sendOtp(String identifier) async {
//     try {
//       isLoading(true);
//       debugPrint('[OTP] Attempting to send OTP to: $identifier');

//       final response = await _apiService.sendOtp(identifier);
//       debugPrint('[OTP] Response: ${response.toString()}');

//       if (response['message'] == 'OTP sent successfully') {
//         // Show popup
//         PopupService.show(
//           type: PopupType.success,
//           title: 'OTP Sent',
//           message: 'An OTP has been sent to $identifier',
//           autoDismiss: true,
//         );
//         // Wait for auto-dismiss duration (adjust to match PopupService duration)
//         await Future.delayed(const Duration(seconds: 1));
//         // Navigate after popup is dismissed
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           Get.toNamed('/otp-verify', arguments: {'identifier': identifier});
//         });
//       } else {
//         PopupService.show(
//           type: PopupType.error,
//           title: 'Error',
//           message: 'Failed to Send OTP\nTry again later',
//         );
//         // Optional: Wait for error popup to dismiss
//         await Future.delayed(const Duration(seconds: 2));
//       }
//     } on AppException catch (e) {
//       debugPrint('[OTP] Error: ${e.message}');
//       _showError(e.message);
//       rethrow;
//     } catch (e, stackTrace) {
//       debugPrint('[OTP] Unexpected error: $e');
//       debugPrint(stackTrace.toString());
//       _showError('Failed to send OTP. Please try again.');
//       rethrow;
//     } finally {
//       isLoading(false);
//     }
//   }

//   // Future<void> verifyOtp(String identifier, String otp) async {
//   //   try {
//   //     isLoading(true);
//   //     debugPrint('[AuthController] Verifying OTP for: $identifier');

//   //     final user = await _apiService.verifyOtp(
//   //       otp: otp,
//   //       identifier: identifier,
//   //     );

//   //     await saveAuthData(user.toJson());
//   //     navigateBasedOnRole();
//   //     // navigateBasedOnRole(user.role.toString());

//   //     // Show success popup (optional, depending on UX)
//   //     PopupService.show(
//   //       type: PopupType.success,
//   //       title: 'Login Successful',
//   //       message: 'Welcome back!',
//   //       autoDismiss: true,
//   //     );
//   //   } on AppException catch (e) {
//   //     debugPrint('[AuthController] AppException: ${e.message}');
//   //     PopupService.show(
//   //       type: PopupType.error,
//   //       title: 'Verification Failed',
//   //       message: e.message,
//   //       autoDismiss: true,
//   //     );
//   //   } catch (e, stackTrace) {
//   //     debugPrint('[AuthController] Unexpected error: $e');
//   //     debugPrint(stackTrace.toString());
//   //     PopupService.show(
//   //       type: PopupType.error,
//   //       title: 'Verification Failed',
//   //       message: 'OTP verification failed. Please try again.',
//   //       autoDismiss: true,
//   //     );
//   //   } finally {
//   //     isLoading(false);
//   //   }

//   Future<void> verifyOtp(String identifier, String otp) async {
//     try {
//       isLoading(true);
//       debugPrint('[AuthController] Verifying OTP for: $identifier');

//       final user = await _apiService.verifyOtp(
//         otp: otp,
//         identifier: identifier,
//       );

//       final prefs = await SharedPreferences.getInstance();
//       currentUser.value = UserModel(
//         uid: prefs.getString('uid') ?? '',
//         fullName: prefs.getString('fullName') ?? '',
//         email: prefs.getString('email'),
//         phoneNumber: prefs.getString('phoneNumber'),
//         role: prefs.getString('role') ?? '',
//         address: prefs.getString('address'),
//         profileImageUrl: prefs.getString('profileImageUrl'),
//         token: await TokenService.getAccessToken(),
//       );
//       // await saveAuthData(user.toJson());
//       await saveAuthData(user as Map<String, dynamic>);

//       navigateBasedOnRole();

//       PopupService.show(
//         type: PopupType.success,
//         title: 'Login Successful',
//         message: 'Welcome back!',
//         autoDismiss: true,
//       );
//     } on AppException catch (e) {
//       debugPrint('[AuthController] AppException: ${e.message}');

//       await Future.delayed(Duration(seconds: 2));
//       PopupService.show(
//         type: PopupType.error,
//         title: 'Verification Failed',
//         message: e.message,
//         autoDismiss: true,
//       );

//       rethrow; // Prevent success flow
//     } catch (e, stackTrace) {
//       debugPrint('[AuthController] Unexpected error: $e');
//       debugPrint(stackTrace.toString());
//       PopupService.show(
//         type: PopupType.error,
//         title: 'Verification Failed',
//         message: 'OTP verification failed. Please try again.',
//         autoDismiss: true,
//       );
//       rethrow; // Prevent success flow
//     } finally {
//       isLoading(false);
//     }
//   }

//   void _showError(String message) {
//     errorMessage.value = message;
//     PopupService.show(
//       type: PopupType.error,
//       title: 'Error',
//       message: message,
//       autoDismiss: true,
//     );
//   }
// }
