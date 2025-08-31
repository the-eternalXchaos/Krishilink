// lib/features/admin/controller/admin_moderation_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/token_service.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminModerationController extends GetxController {
  final offensiveWords = <String>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOffensiveWords();
  }

  Future<void> fetchOffensiveWords() async {
    try {
      isLoading(true);
      // Mock; replace with API
      offensiveWords.assignAll(['example']);
    } catch (e) {
      PopupService.error('Failed to load offensive words: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addOffensiveWord(String word) async {
    try {
      isLoading(true);
      final response = await http.post(
        Uri.parse(ApiConstants.addOffensiveWordEndpoint),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
        },
        body: {'offensiveWord': word, 'secretCode': 'admin_secret'},
      );

      if (response.statusCode == 200) {
        offensiveWords.add(word);
        PopupService.success('Offensive word added');
      } else {
        throw Exception('Failed to add offensive word');
      }
    } catch (e) {
      PopupService.error('Failed to add offensive word: $e');
    } finally {
      isLoading(false);
    }
  }
}
