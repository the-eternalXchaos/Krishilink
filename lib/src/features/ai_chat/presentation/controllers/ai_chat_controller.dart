import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:path/path.dart';

class AiChatController extends GetxController {
  // --- UI state ---
  final inputController = TextEditingController();
  final inputText = ''.obs;
  final scrollController = ScrollController();
  final messages = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isAtBottom = true.obs;

  // Chat meta
  final aiChats = <Map<String, dynamic>>[].obs;
  final selectedChatId = ''.obs;
  String? userName;

  // ---------- init state
  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      // reverse:true ⇒ bottom is near 0
      final atBottom = scrollController.position.pixels <= 50.0;

      if (isAtBottom.value != atBottom) {
        isAtBottom.value = atBottom;
      }
    });
  }

  void setUserName(String name) => userName = name;

  // ---------- public actions ----------
  //
  List _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['data'] is List) return body['data'] as List;
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  Map<String, dynamic> _normalizeChat(dynamic raw) {
    final m = _asMap(raw);
    if (m == null) {
      return {
        'id': '',
        'title': 'Conversation',
        'preview': '',
        'timestamp': null,
      };
    }

    final id = (m['chatId'] ?? m['aiChatId'] ?? m['id'] ?? '').toString();
    final title = (m['title'] ?? 'Conversation').toString();

    DateTime? ts;
    final createdAtStr = m['createdAt']?.toString();
    if (createdAtStr != null) {
      ts = DateTime.tryParse(createdAtStr)?.toLocal();
    }

    return {
      'id': id,
      'title': title,
      'preview': (m['preview'] ?? m['lastMessage'] ?? '').toString(),
      'timestamp': ts,
      '__raw': m,
    };
  }

  void sendDefaultMessage(String message) {
    inputController.text = message;
    inputText.value = message;
    sendMessage();
  }

  Future<void> sendMessage() async {
    final content = inputController.text.trim();
    if (content.isEmpty) {
      PopupService.warning('message_empty'.tr);
      return;
    }
    if (isLoading.value) return;

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

    final hadSelected = selectedChatId.value.isNotEmpty;

    try {
      final response = await _callAiApi(content);
      messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
        'error': false,
      });

      // If this was the first message of a *new thread*, pick up the new chatID
      if (!hadSelected && selectedChatId.value.isEmpty) {
        await loadAiChats(); // newest first
        if (aiChats.isNotEmpty) {
          selectedChatId.value = aiChats.first['id'].toString();
        }
      }
    } catch (e) {
      messages.add({
        'role': 'assistant',
        'content': 'failed_to_get_response'.trParams({'error': e.toString()}),
        'timestamp': DateTime.now(),
        'error': true,
        'originalMessage': content,
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

  // ---------- chat list (history) ----------
  Future<void> loadAiChats() async {
    try {
      final dio = await _authorizedDio();
      final res = await dio.get(ApiConstants.getAiChatsEndpoint);

      final list = _asList(res.data); // ✅ handles both {data:[...]} and [...]
      final normalized =
          list
              .map<Map<String, dynamic>>((item) => _normalizeChat(item))
              .where((m) => (m['id'] as String).isNotEmpty)
              .toList();

      normalized.sort((a, b) {
        final aTs = a['timestamp'] as DateTime?;
        final bTs = b['timestamp'] as DateTime?;
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs); // newest first
      });

      aiChats.assignAll(normalized);
    } catch (e) {
      debugPrint('Error loading chats: $e');
      PopupService.error('Failed to load chats');
    }
  }

  Future<void> openChat(String aiChatId) async {
    try {
      selectedChatId.value = aiChatId;

      final dio = await _authorizedDio();
      final res = await dio.get(
        '${ApiConstants.getAiChatMessagesEndpoint}/$aiChatId',
      );

      final body = res.data;
      final raw =
          body is List ? body : (body is Map ? (body['data'] ?? []) : []);

      final list = <Map<String, dynamic>>[];

      for (final item in raw) {
        if (item is! Map) continue;

        final createdAtStr = item['createdAt']?.toString();
        final ts =
            (createdAtStr != null
                ? DateTime.tryParse(createdAtStr)?.toLocal()
                : null) ??
            DateTime.now();

        final prompt = (item['prompt'] ?? '').toString();
        final resp = (item['response'] ?? '').toString();

        if (prompt.isNotEmpty) {
          list.add({
            'role': 'user',
            'content': prompt,
            'timestamp': ts,
            'error': false,
          });
        }
        if (resp.isNotEmpty) {
          list.add({
            'role': 'assistant',
            'content': resp,
            'timestamp': ts,
            'error': false,
          });
        }
      }

      // Your ListView is reverse:true ⇒ keep ascending order here
      list.sort(
        (a, b) =>
            (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime),
      );

      messages.assignAll(list);
      scrollToBottom();
    } catch (e) {
      PopupService.error('Failed to open chat: $e');
      debugPrint('Error opening chat: $e');
    }
  }

  Future<bool> deleteChat(String aiChatId) async {
    try {
      final dio = await _authorizedDio();
      final res = await dio.delete(
        '${ApiConstants.deleteAiChatEndpoint}/$aiChatId',
      );

      final ok = res.statusCode == 200 || res.statusCode == 204;

      if (ok) {
        aiChats.removeWhere((c) => (c['id']?.toString() ?? '') == aiChatId);
        if (selectedChatId.value == aiChatId) {
          messages.clear();
          selectedChatId.value = '';
        }
      }
      return ok;
    } catch (e) {
      PopupService.error('Failed to delete chat: $e');
      debugPrint('Error deleting chat: $e');
      return false;
    }
  }

  // ---------- retry ----------
  Future<void> retryMessage(int index) async {
    final msg = messages[index];
    if (msg['error'] != true) return;

    final originalMessage = msg['originalMessage'] ?? msg['content'];
    messages.removeAt(index);

    final messageContent = originalMessage.toString().replaceAll(
      ' (Image sent)',
      '',
    );
    inputController.text = messageContent;

    if (originalMessage.toString().contains('(Image sent)')) {
      await sendMessage(); // retry as text
    } else {
      await sendMessage();
    }
  }

  // ---------- http helpers ----------
  Future<Dio> _authorizedDio() async {
    final dio = Dio();
    try {
      final headers = await TokenService.getAuthHeaders();
      dio.options.headers.addAll(headers);
    } catch (_) {
      // guest fallback
      dio.options.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': '*/*',
      });
    }
    return dio;
  }

  Future<String> _callAiApi(String message) async {
    final dio = await _authorizedDio();

    final qp = <String, dynamic>{};
    if (selectedChatId.value.isNotEmpty) {
      qp['chatID'] = selectedChatId.value; // <- keep thread
    }

    try {
      final response = await dio.post(
        ApiConstants.chatWithAiEndpoint,
        queryParameters: qp,
        data: jsonEncode(message), // API expects raw JSON string: "hi"
        options: Options(
          responseType: ResponseType.plain,
        ), // content-type: text/plain
      );

      if (response.statusCode == 200) {
        return response.data?.toString() ?? '';
      } else if (response.statusCode == 401) {
        return 'I apologize, but I cannot process your request at the moment. Please try logging in again or contact support if the issue persists.';
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return 'Authentication required. Please log in to use AI chat.';
      } else if (e.response?.statusCode == 400) {
        return 'Invalid request. Please check your message and try again.';
      } else if (e.response?.statusCode == 500) {
        return 'Server error: ${e.response?.data ?? 'Unknown server error'}. Please try again later.';
      } else {
        return 'Network error: ${e.response?.statusCode ?? 'Unknown'} - ${e.response?.data ?? e.message}';
      }
    } catch (e) {
      if (e.toString().contains('Authentication required') ||
          e.toString().contains('Session expired')) {
        return 'I apologize, but there seems to be an authentication issue. Please try logging in again or contact support if the problem continues.';
      }
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> _callAiImageApi(String message, File image) async {
    final dio = await _authorizedDio();

    final formData = FormData.fromMap({
      'message': message,
      'userName': userName ?? 'User',
      'image': await MultipartFile.fromFile(
        image.path,
        filename: basename(image.path),
      ),
    });

    final response = await dio.post(
      'https://api.example.com/ai/image-chat', // <- replace with your real endpoint
      data: formData,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['response'] is String) {
        return data['response'] as String;
      }
      return 'Image processed successfully!';
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  // ---------- utils ----------
  void clearChat() {
    messages.clear();
    inputController.clear();
    isAtBottom.value = true;
  }

  // start new chat ko lagi
  void startNewChat() {
    clearChat();
    selectedChatId.value = '';
  }

  void scrollToBottom() {
    // our list is in reverse order for ascending order  , so
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      // reverse:true ⇒ 0.0 is the bottom
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
