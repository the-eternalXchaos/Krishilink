// lib/features/farmer/controller/farmer_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/farmer/data/farmer_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_model.dart';
import '../models/crop_model.dart';
import 'package:krishi_link/src/core/components/product/product_form_data.dart';

class FarmerController extends GetxController {
  final FarmerApiService apiServices =
      Get.isRegistered() ? Get.find<FarmerApiService>() : FarmerApiService();
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<TutorialModel> tutorials = <TutorialModel>[].obs;
  final RxList<CropModel> crops = <CropModel>[].obs;
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  // final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  Null get selectedFarmer => null;
  Null get farmersList => null;

  @override
  void onInit() {
    super.onInit();
    fetchCrops();
    Future.delayed(Durations.medium1, () {
      fetchTutorials();
      fetchOrders();
    });
  }

  Future<void> _updateLoading(bool value) async {
    isLoading.value = value;
  }

  // Dummy data for crops
  List<CropModel> get _dummyCrops => [
    CropModel(
      id: '1',
      name: 'Tomato',
      plantedAt: DateTime.now().subtract(const Duration(days: 30)),
      note: 'Regular watering required',
      description: '100 sqm field',
      status: 'Healthy',
      suggestions: 'Apply organic fertilizer',
      disease: null,
      careInstructions: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    CropModel(
      id: '2',
      name: 'Potato',
      plantedAt: DateTime.now().subtract(const Duration(days: 60)),
      note: 'Check for pests',
      description: '200 sqm field',
      status: 'At Risk',
      suggestions: 'Use pest control',
      disease: 'Late Blight',
      careInstructions: 'Apply fungicide and monitor',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> fetchTutorials() async {
    try {
      await _updateLoading(true);
      final fetchedTutorials = await apiServices.fetchTutorials();
      tutorials.assignAll(fetchedTutorials);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_tutorials'.trParams({
        'error': e.toString(),
      });
      // PopupService.error(errorMessage.value); TODO REmove it later after backend it ready
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> fetchCrops() async {
    try {
      await _updateLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final cropsJson = prefs.getStringList('crops');
      if (cropsJson == null || cropsJson.isEmpty) {
        // Initialize with dummy data
        crops.assignAll(_dummyCrops);
        await _cacheCrops(_dummyCrops);
      } else {
        crops.assignAll(
          cropsJson
              .map((json) => CropModel.fromJson(jsonDecode(json)))
              .toList(),
        );
      }
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_crops'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> _cacheCrops(List<CropModel> crops) async {
    final prefs = await SharedPreferences.getInstance();
    final cropsJson = crops.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList('crops', cropsJson);
  }

  Future<void> addCrop(
    CropModel crop, {
    required String cropName,
    required String area,
    required String plantingDate,
    required String location,
    required String emailOrPhone,
    String? description,
  }) async {
    try {
      await _updateLoading(true);
      final newCrop = CropModel(
        id: crop.id,
        name: cropName,
        plantedAt: DateTime.parse(plantingDate),
        note: crop.note,
        description: description,
        status: crop.status ?? 'Healthy',
        suggestions: crop.suggestions ?? '',
        disease: crop.disease,
        careInstructions: crop.careInstructions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      crops.add(newCrop);
      crops.refresh();
      await _cacheCrops(crops);
      PopupService.success('crop_added'.tr);
    } catch (e) {
      errorMessage.value = 'failed_to_add_crop'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> updateCrop(
    String cropId,
    String cropName,
    String? area,
    String plantingDate,
    String? note,
    String? description,
  ) async {
    try {
      await _updateLoading(true);
      final index = crops.indexWhere((c) => c.id == cropId);
      if (index != -1) {
        final existingCrop = crops[index];
        final updatedCrop = CropModel(
          id: cropId,
          name: cropName,
          plantedAt: DateTime.parse(plantingDate),
          note: note,
          description: description ?? area,
          status: existingCrop.status,
          suggestions: existingCrop.suggestions,
          disease: existingCrop.disease,
          careInstructions: existingCrop.careInstructions,
          createdAt: existingCrop.createdAt,
          updatedAt: DateTime.now(),
        );
        crops[index] = updatedCrop;
        crops.refresh();
        await _cacheCrops(crops);
        PopupService.success('crop_updated'.tr);
      } else {
        throw Exception('Crop not found');
      }
    } catch (e) {
      errorMessage.value = 'failed_to_update_crop'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> deleteCrop(String cropId) async {
    try {
      await _updateLoading(true);
      crops.removeWhere((c) => c.id == cropId);
      crops.refresh();
      await _cacheCrops(crops);
      PopupService.success('crop_deleted'.tr);
    } catch (e) {
      errorMessage.value = 'failed_to_delete_crop'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> updateCropHealth(
    String cropId, {
    required String status,
    String? disease,
    String? careInstructions,
    String? suggestions,
  }) async {
    try {
      await _updateLoading(true);
      final index = crops.indexWhere((c) => c.id == cropId);
      if (index == -1) throw Exception('Crop not found');
      final existing = crops[index];
      final updated = CropModel(
        id: existing.id,
        name: existing.name,
        description: existing.description,
        imageUrl: existing.imageUrl,
        plantedAt: existing.plantedAt,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        note: existing.note,
        status: status,
        disease: disease ?? existing.disease,
        careInstructions: careInstructions ?? existing.careInstructions,
        suggestions: suggestions ?? existing.suggestions,
      );
      crops[index] = updated;
      crops.refresh();
      await _cacheCrops(crops);
      PopupService.showSnackbar(
        type: PopupType.success,
        title: 'Crop health updated',
        message: 'The health status of the crop has been successfully updated.',
      );
    } catch (e) {
      PopupService.showSnackbar(
        type: PopupType.error,
        title: 'Error',
        message: 'Failed to update crop health: $e',
      );
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> fetchOrders() async {
    try {
      await _updateLoading(true);
      final fetchedOrders = await apiServices.fetchOrders();
      orders.assignAll(fetchedOrders);
      filteredOrders.assignAll(fetchedOrders);
      PopupService.success('orders_fetched'.tr);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_orders'.trParams({
        'error': e.toString(),
      });
      PopupService.error(errorMessage.value);
    } finally {
      await _updateLoading(false);
    }
  }

  void filterOrdersByStatus(String? status) {
    if (status == null || status == 'All') {
      filteredOrders.assignAll(orders);
    } else {
      filteredOrders.assignAll(
        orders
            .where(
              (order) =>
                  order.orderStatus.toLowerCase() == status.toLowerCase(),
            )
            .toList(),
      );
    }
  }

  void searchOrders(String query) {
    if (query.isEmpty) {
      filteredOrders.assignAll(orders);
    } else {
      filteredOrders.assignAll(
        orders
            .where(
              (order) =>
                  order.productName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  order.orderId.toLowerCase().contains(query.toLowerCase()),
            )
            .toList(),
      );
    }
  }
}
