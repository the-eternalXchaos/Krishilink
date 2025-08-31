import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/exceptions/app_exception.dart';

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

  // Helper method to ensure consistent message sending
  void sendDefaultMessage(String message) {
    debugPrint('📤 [AI Chat] Sending default message: $message');
    // Set the text in the input controller
    inputController.text = message;
    // Update the reactive input text value (same as typing)
    inputText.value = message;
    // Send the message using the same flow
    sendMessage();
  }

  Future<void> sendMessage() async {
    final content = inputController.text.trim();
    if (content.isEmpty) {
      PopupService.warning('message_empty'.tr);
      return;
    }

    debugPrint('📤 [AI Chat] Sending message: $content');

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
      debugPrint('📤 [AI Chat] Calling AI API...');
      final response = await _callAiApi(content);
      debugPrint('✅ [AI Chat] AI response received: $response');

      messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
        'error': false,
      });
    } catch (e) {
      debugPrint('❌ [AI Chat] Error in sendMessage: $e');
      messages.add({
        'role': 'assistant',
        'content': 'failed_to_get_response'.trParams({'error': e.toString()}),
        'timestamp': DateTime.now(),
        'error': true,
        'originalMessage': content, // Store the original message for retry
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
  //getter to use call api 
  get callAiApi => _callAiApi;

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
        headers = {'Content-Type': 'application/json', 'Accept': '*/*'};
      }

      final response = await dio.post(
        ApiConstants.chatWithAiEndpoint,
        // keep this because using this will oly work the message
        data: jsonEncode(message),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        if (response.data is String) {
          return response.data;
        } else {
          return response.data.toString();
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - show guest message instead of redirecting
        return 'I apologize, but I cannot process your request at the moment. Please try logging in again or contact support if the issue persists.';
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ [AI Chat] Error: $e');
      if (e is DioException) {
        debugPrint('❌ [AI Chat] Dio error details: ${e.response?.data}');
        debugPrint('❌ [AI Chat] Dio error status: ${e.response?.statusCode}');
        debugPrint('❌ [AI Chat] Dio error headers: ${e.response?.headers}');

        // Return more specific error messages
        if (e.response?.statusCode == 401) {
          return 'Authentication required. Please log in to use AI chat.';
        } else if (e.response?.statusCode == 400) {
          return 'Invalid request. Please check your message and try again.';
        } else if (e.response?.statusCode == 500) {
          return 'Server error: ${e.response?.data ?? 'Unknown server error'}. Please try again later.';
        } else {
          return 'Network error: ${e.response?.statusCode ?? 'Unknown'} - ${e.response?.data ?? e.message}';
        }
      }

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

    debugPrint(
      '🔄 [AI Chat] Retrying message at index $index: ${msg['content']}',
    );

    // Get the original user message, not the error message
    final originalMessage = msg['originalMessage'] ?? msg['content'];

    // Remove the failed message
    messages.removeAt(index);

    // Set the original message content in the input controller
    final messageContent = originalMessage.replaceAll(' (Image sent)', '');
    inputController.text = messageContent;

    // Send the message again
    if (originalMessage.contains('(Image sent)')) {
      // Note: Image retry requires re-picking the image; simplify by assuming text-only retry
      debugPrint(
        '🔄 [AI Chat] Retrying image message as text: $messageContent',
      );
      await sendMessage();
    } else {
      debugPrint('🔄 [AI Chat] Retrying text message: $messageContent');
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
