import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/src/features/order/model/order_model.dart';
import 'package:path/path.dart';

// DTOs for requests
class AddCropRequest {
  final String cropName;
  final String area;
  final String plantingDate;
  final String location;
  final String emailOrPhone;
  final String? description;

  const AddCropRequest({
    required this.cropName,
    required this.area,
    required this.plantingDate,
    required this.location,
    required this.emailOrPhone,
    this.description,
  });

  Map<String, dynamic> toMap() => {
    'CropName': cropName,
    'Area': area,
    'PlantingDate': plantingDate,
    'Location': location,
    'EmailorPhone': emailOrPhone,
    'Description': description ?? '',
  };
}

class UpdateCropRequest {
  final String cropName;
  final String plantingDate;
  final String description;

  const UpdateCropRequest({
    required this.cropName,
    required this.plantingDate,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
    'CropName': cropName,
    'PlantingDate': plantingDate,
    'Description': description,
  };
}

/// Farmer API service for managing crops, tutorials, and farmer-specific data
class FarmerApiService extends BaseService {
  FarmerApiService({super.apiClient});

  /// Fetch all tutorials
  Future<List<TutorialModel>> fetchTutorials() async {
    return executeApiCall(() async {
      final response = await apiClient.get(ApiConstants.getTutorialsEndpoint);

      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((e) => TutorialModel.fromJson(e)).toList();
      }
      return <TutorialModel>[];
    });
  }

  /// Fetch all crops for the current farmer
  Future<List<CropModel>> fetchCrops() async {
    return executeApiCall(() async {
      final response = await apiClient.get(ApiConstants.getCropsEndpoint);

      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((e) => CropModel.fromJson(e)).toList();
      }
      return <CropModel>[];
    });
  }

  /// Add a new crop
  Future<CropModel> addCrop(AddCropRequest request) async {
    return executeApiCall(() async {
      final formData = FormData.fromMap(request.toMap());

      final response = await apiClient.post(
        ApiConstants.addCropEndpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        final cropId =
            responseData['data']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        return CropModel(
          id: cropId,
          name: request.cropName,
          plantedAt:
              request.plantingDate.isNotEmpty
                  ? DateTime.parse(request.plantingDate)
                  : DateTime.now(),
          description: request.description ?? 'No description',
        );
      }

      throw Exception(
        'Failed to add crop: ${responseData['message'] ?? 'Unknown error'}',
      );
    });
  }

  /// Update an existing crop
  Future<CropModel> updateCrop(String cropId, CropModel crop) async {
    return executeApiCall(() async {
      final request = UpdateCropRequest(
        cropName: crop.name,
        plantingDate: crop.plantedAt?.toIso8601String() ?? '',
        description: crop.description ?? 'No description added',
      );

      final formData = FormData.fromMap(request.toMap());

      final response = await apiClient.put(
        '${ApiConstants.updateCropEndpoint}/$cropId',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      final responseData = response.data;
      if (responseData['success'] == true) {
        return crop;
      }

      throw Exception(
        'Failed to update crop: ${responseData['message'] ?? 'Unknown error'}',
      );
    });
  }

  /// Delete a crop
  Future<void> deleteCrop(String cropId) async {
    return executeApiCall(() async {
      await apiClient.delete('${ApiConstants.deleteCropEndpoint}/$cropId');
    });
  }

  /// Fetch orders for the current farmer
  Future<List<OrderModel>> fetchOrders() async {
    return executeApiCall(() async {
      final response = await apiClient.get(ApiConstants.getMyOrdersEndpoint);

      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return data.map((e) => OrderModel.fromJson(e)).toList();
      }
      return <OrderModel>[];
    });
  }

  /// Upload product image (if needed for farmer products)
  Future<String> uploadProductImage(File imageFile) async {
    return executeApiCall(() async {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: basename(imageFile.path),
          contentType: MediaType(
            'image',
            extension(imageFile.path).replaceFirst('.', ''),
          ),
        ),
      });

      final response = await apiClient.post(
        '/upload/product-image', // Adjust endpoint as needed
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return response.data['imageUrl'] ?? response.data['url'] ?? '';
    });
  }
}
