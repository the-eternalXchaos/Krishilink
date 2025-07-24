import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:krishi_link/features/auth/controller/auth_controller.dart';

class DiseaseController extends GetxController {
  final isLoading = false.obs;
  final result = ''.obs;
  final error = ''.obs;

  Future<void> detectDisease(String imagePath) async {
    isLoading.value = true;
    result.value = '';
    error.value = '';
    final authController = Get.find<AuthController>();
    final token = authController.currentUser.value?.token ?? '';

    final dioClient = dio.Dio();
    final formData = dio.FormData.fromMap({
      'cropImage': await dio.MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
    });

    try {
      final response = await dioClient.post(
        'https://krishilink.shamir.com.np/api/AI/detectDisease',
        data: formData,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      if (response.statusCode == 200) {
        result.value = response.data.toString();
        error.value = '';
      } else {
        error.value = 'Failed: \\${response.statusCode}';
        result.value = '';
      }
    } catch (e) {
      error.value = 'Error: $e';
      result.value = '';
    } finally {
      isLoading.value = false;
    }
  }
}
