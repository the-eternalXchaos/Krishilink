import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http_parser/http_parser.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_service.dart';
import 'package:path/path.dart' as p;

class DiseaseController extends GetxController {
  final isLoading = false.obs;
  final result = ''.obs;
  final error = ''.obs;

  Future<void> detectDisease(String imagePath) async {
    isLoading.value = true;
    result.value = '';
    error.value = '';

    // controller and services , temp
    final _ =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final apiService =
        Get.isRegistered<ApiService>()
            ? Get.find<ApiService>()
            : Get.put(ApiService());
    final dioClient = apiService.dio;

    // Prepare multipart
    final fileName = p.basename(imagePath);
    final ext = p.extension(fileName).toLowerCase();

    dio.MultipartFile filePart;
    if (ext == '.jpg' || ext == '.jpeg') {
      filePart = await dio.MultipartFile.fromFile(
        imagePath,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );
    } else if (ext == '.png') {
      filePart = await dio.MultipartFile.fromFile(
        imagePath,
        filename: fileName,
        contentType: MediaType('image', 'png'),
      );
    } else if (ext == '.webp') {
      filePart = await dio.MultipartFile.fromFile(
        imagePath,
        filename: fileName,
        contentType: MediaType('image', 'webp'),
      );
    } else {
      filePart = await dio.MultipartFile.fromFile(
        imagePath,
        filename: fileName,
      );
    }

    final formData = dio.FormData.fromMap({'cropImage': filePart});

    try {
      debugPrint('POST ${ApiConstants.detectDiseaseEndpoint}');
      final response = await dioClient.post(
        ApiConstants.detectDiseaseEndpoint,
        data: formData,
        options: dio.Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        result.value = response.data.toString();
        error.value = '';
      } else {
        error.value =
            _extractFriendlyMessage(response.data) ??
            'Something went wrong. Please try again.';
        result.value = '';
      }
    } on dio.DioException catch (e) {
      final res = e.response;
      error.value =
          res != null
              ? (_extractFriendlyMessage(res.data) ?? 'Request failed')
              : 'Network error: ${e.message}';
      result.value = '';
    } catch (e) {
      error.value = 'Error: $e';
      result.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  String? _extractFriendlyMessage(dynamic data) {
    try {
      if (data is Map) {
        final title = (data['title'] as String?)?.trim();
        final errors = data['errors'];
        final messages = <String>[];
        if (title != null && title.isNotEmpty) messages.add(title);
        if (errors is Map) {
          if (errors.containsKey('imageValidation')) {
            final iv = errors['imageValidation'];
            if (iv is List) {
              for (final msg in iv) {
                if (msg is String && msg.isNotEmpty) messages.add(msg);
              }
            } else if (iv is String && iv.isNotEmpty) {
              messages.add(iv);
            }
          } else {
            for (final entry in errors.entries) {
              final val = entry.value;
              if (val is List) {
                for (final msg in val) {
                  if (msg is String && msg.isNotEmpty) messages.add(msg);
                }
              } else if (val is String && val.isNotEmpty) {
                messages.add(val);
              }
            }
          }
        }
        if (messages.isNotEmpty) return messages.join('\n');
        final message = (data['message'] ?? data['detail']) as String?;
        if (message != null && message.isNotEmpty) return message;
      } else if (data is String) {
        return data;
      }
    } catch (_) {}
    return null;
  }
}
