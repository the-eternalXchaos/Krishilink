// import 'package:flutter/material.dart';
// import 'package:get/get.dart' hide FormData, MultipartFile;
// import 'package:http/http.dart' as http;
// import 'package:dio/dio.dart';
// import 'package:path/path.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'package:krishi_link/core/constants/api_constants.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';

// class AiChatController extends GetxController {
//   final inputController = TextEditingController();
//   final scrollController = ScrollController();
//   final messages = <Map<String, dynamic>>[].obs;
//   final isLoading = false.obs;
//   final isAtBottom = true.obs; // Track if user is at bottom
//   String? userName;

//   @override
//   void onInit() {
//     super.onInit();
//     // Listen to scroll events to toggle auto-scroll
//     scrollController.addListener(() {
//       if (scrollController.hasClients) {
//         final isBottom =
//             scrollController.position.pixels >=
//             scrollController.position.maxScrollExtent - 50;
//         if (isAtBottom.value != isBottom) {
//           isAtBottom.value = isBottom;
//         }
//       }
//     });
//   }

//   void setUserName(String name) {
//     userName = name;
//   }

//   Future<void> sendMessage() async {
//     final content = inputController.text.trim();
//     if (content.isEmpty) {
//       Get.snackbar('error'.tr, 'message_empty'.tr);
//       return;
//     }

//     messages.add({
//       'role': 'user',
//       'content': content,
//       'timestamp': DateTime.now(),
//       'error': false,
//     });
//     inputController.clear();
//     isLoading.value = true;
//     if (isAtBottom.value) scrollToBottom();

//     try {
//       final response = await _callAiApi(content);
//       messages.add({
//         'role': 'assistant',
//         'content': response,
//         'timestamp': DateTime.now(),
//         'error': false,
//       });
//     } catch (e) {
//       messages.add({
//         'role': 'assistant',
//         'content': 'failed_to_get_response'.trParams({'error': e.toString()}),
//         'timestamp': DateTime.now(),
//         'error': true,
//       });
//     } finally {
//       isLoading.value = false;
//       if (isAtBottom.value) scrollToBottom();
//     }
//   }

//   Future<void> sendImageMessage(String message, File image) async {
//     final content = message.isEmpty ? 'Image sent' : '$message (Image sent)';
//     messages.add({
//       'role': 'user',
//       'content': content,
//       'timestamp': DateTime.now(),
//       'error': false,
//     });
//     isLoading.value = true;
//     if (isAtBottom.value) scrollToBottom();

//     try {
//       final response = await _callAiImageApi(message, image);
//       messages.add({
//         'role': 'assistant',
//         'content': response,
//         'timestamp': DateTime.now(),
//         'error': false,
//       });
//     } catch (e) {
//       messages.add({
//         'role': 'assistant',
//         'content': 'failed_to_process_image'.trParams({'error': e.toString()}),
//         'timestamp': DateTime.now(),
//         'error': true,
//       });
//     } finally {
//       isLoading.value = false;
//       if (isAtBottom.value) scrollToBottom();
//     }
//   }

//   Future<String> _callAiApi(String message) async {
//     final dio = Dio();
//     final authController = Get.find<AuthController>();
//     final token = authController.currentUser.value?.token ?? '';

//     final response = await dio.post(
//       ApiConstants.chatWithAiEndpoint,
//       data: jsonEncode(message), // Send the string as JSON
//       options: Options(
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token', // <-- This is required!
//         },
//       ),
//     );
//     if (response.statusCode == 200) {
//       // The backend may return a string or a JSON object; handle both
//       if (response.data is String) {
//         return response.data;
//       } else if (response.data is Map && response.data['response'] != null) {
//         return response.data['response'];
//       } else {
//         return response.data.toString();
//       }
//     } else {
//       throw Exception('API error: ${response.statusCode}');
//     }
//   }

//   Future<String> _callAiImageApi(String message, File image) async {
//     final dio = Dio();
//     final formData = FormData.fromMap({
//       'message': message,
//       'userName': userName ?? 'User',
//       'image': await MultipartFile.fromFile(
//         image.path,
//         filename: basename(image.path),
//       ),
//     });
//     final response = await dio.post(
//       'https://api.example.com/ai/image-chat',
//       data: formData,
//     );
//     if (response.statusCode == 200) {
//       return response.data['response'] ?? 'Image processed successfully!';
//     } else {
//       throw Exception('API error: ${response.statusCode}');
//     }
//   }

//   void retryMessage(int index) async {
//     final msg = messages[index];
//     if (msg['error'] != true) return;

//     messages.removeAt(index);
//     inputController.text = msg['content'].replaceAll(' (Image sent)', '');
//     if (msg['content'].contains('(Image sent)')) {
//       // Note: Image retry requires re-picking the image; simplify by assuming text-only retry
//       await sendMessage();
//     } else {
//       await sendMessage();
//     }
//   }

//   void clearChat() {
//     messages.clear();
//     inputController.clear();
//     isAtBottom.value = true;
//   }

//   void scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (scrollController.hasClients) {
//         scrollController.animateTo(
//           scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void onClose() {
//     inputController.dispose();
//     scrollController.dispose();
//     super.onClose();
//   }
// }

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:krishi_link/core/constants/api_constants.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:path/path.dart';

class AiChatController extends GetxController {
  final inputController = TextEditingController();
  final inputText = ''.obs;
  final scrollController = ScrollController();
  final messages = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isAtBottom = true.obs; // Track if user is at bottom
  String? userName;

  @override
  void onInit() {
    super.onInit();
    // Listen to scroll events to toggle auto-scroll
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        final isBottom =
            scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 50;
        if (isAtBottom.value != isBottom) {
          isAtBottom.value = isBottom;
        }
      }
    });
  }

  void setUserName(String name) {
    userName = name;
  }

  Future<void> sendMessage() async {
    final content = inputController.text.trim();
    if (content.isEmpty) {
      PopupService.warning('message_empty'.tr);
      return;
    }

    messages.add({
      'role': 'user',
      'content': content,
      'timestamp': DateTime.now(),
      'error': false,
    });
    inputController.clear();
    inputText.value = '';
    isLoading.value = true;
    if (isAtBottom.value) scrollToBottom();

    try {
      final response = await _callAiApi(content);
      messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
        'error': false,
      });
    } catch (e) {
      messages.add({
        'role': 'assistant',
        'content': 'failed_to_get_response'.trParams({'error': e.toString()}),
        'timestamp': DateTime.now(),
        'error': true,
      });
    } finally {
      isLoading.value = false;
      if (isAtBottom.value) scrollToBottom();
    }
  }

  Future<void> sendImageMessage(String message, File image) async {
    final content = message.isEmpty ? 'Image sent' : '$message (Image sent)';
    messages.add({
      'role': 'user',
      'content': content,
      'timestamp': DateTime.now(),
      'error': false,
    });
    isLoading.value = true;
    if (isAtBottom.value) scrollToBottom();

    try {
      final response = await _callAiImageApi(message, image);
      messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
        'error': false,
      });
    } catch (e) {
      messages.add({
        'role': 'assistant',
        'content': 'failed_to_process_image'.trParams({'error': e.toString()}),
        'timestamp': DateTime.now(),
        'error': true,
      });
    } finally {
      isLoading.value = false;
      if (isAtBottom.value) scrollToBottom();
    }
  }

  Future<String> _callAiApi(String message) async {
    final dio = Dio();

    try {
      // Try to get authenticated headers, but don't fail if not available
      Map<String, String> headers = {};
      try {
        headers = await TokenService.getAuthHeaders();
      } catch (e) {
        // If authentication fails, use basic headers (guest access)
        debugPrint('Using guest access for AI chat: $e');
        headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
      }

      final response = await dio.post(
        ApiConstants.chatWithAiEndpoint,
        data: jsonEncode(message),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        // The backend may return a string or a JSON object; handle both
        if (response.data is String) {
          return response.data;
        } else if (response.data is Map && response.data['response'] != null) {
          return response.data['response'];
        } else {
          return response.data.toString();
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - show guest message instead of redirecting
        return 'I apologize, but I cannot process your request at the moment. Please try logging in again or contact support if the issue persists.';
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        // Handle authentication errors gracefully
        return 'I apologize, but there seems to be an authentication issue. Please try logging in again or contact support if the problem continues.';
      }
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> _callAiImageApi(String message, File image) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'message': message,
      'userName': userName ?? 'User',
      'image': await MultipartFile.fromFile(
        image.path,
        filename: basename(image.path),
      ),
    });
    final response = await dio.post(
      'https://api.example.com/ai/image-chat',
      data: formData,
    );
    if (response.statusCode == 200) {
      return response.data['response'] ?? 'Image processed successfully!';
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  void retryMessage(int index) async {
    final msg = messages[index];
    if (msg['error'] != true) return;

    messages.removeAt(index);
    inputController.text = msg['content'].replaceAll(' (Image sent)', '');
    if (msg['content'].contains('(Image sent)')) {
      // Note: Image retry requires re-picking the image; simplify by assuming text-only retry
      await sendMessage();
    } else {
      await sendMessage();
    }
  }

  void clearChat() {
    messages.clear();
    inputController.clear();
    isAtBottom.value = true;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
