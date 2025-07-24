import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/models/notification_model.dart';
import 'package:krishi_link/features/admin/models/order_model.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/farmer/models/weather_model.dart';
import 'package:krishi_link/services/farmer_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_model.dart'; // Assuming this exists
import '../models/crop_model.dart'; // Assuming this exists
import 'package:krishi_link/core/components/product/product_form_data.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class FarmerController extends GetxController {
  final FarmerApiServices apiServices =
      Get.isRegistered() ? Get.find<FarmerApiServices>() : FarmerApiServices();
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxList<TutorialModel> tutorials = <TutorialModel>[].obs;
  final RxList<CropModel> crops = <CropModel>[].obs;
  final RxList<OrderModel> orders = <OrderModel>[].obs;

  // final RxBool isActive =
  //     false.obs; // Assuming this is used for some feature toggle
  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final Rx<Weather?> weather = Rx<Weather?>(null); // Add weather field
  // final RxBool isLoadingNotifications = false.obs;
  // final RxList<OrderModel> orders = <OrderModel>[].obs;
  @override
  void onInit() {
    super.onInit();
    fetchCrops();
    // fetchProducts();

    Future.delayed(Durations.medium1, () {
      fetchWeather();
      fetchWeather();
      fetchTutorials();
      fetchOrders();
      fetchNotifications();
    });
  }

  Future<void> _updateLoading(bool value) async {
    isLoading.value = value;
  }

  Future<void> fetchWeather({String? location}) async {
    try {
      await _updateLoading(true);
      final authController = Get.find<AuthController>();
      final userLocation =
          location ??
          authController.currentUser.value?.address?.trimRight() ??
          'Kathmandu'; // Fallback to Kathmandu
      final weatherData = await apiServices.fetchWeather(userLocation);
      weather.value = weatherData;
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_weather'.trParams({
        'error': e.toString(),
      });
      // Get.snackbar(
      //   'error'.tr,
      //   errorMessage.value,
      //   backgroundColor: Colors.red.shade100,
      // );
      weather.value = Weather.empty(); // Set empty weather on error
    } finally {
      await _updateLoading(false);
    }
  }

  // Future<void> fetchProducts({
  //   String? searchQuery,
  //   List<String>? selectedCategories,
  //   List<String>? selectedLocations,
  // }) async {
  //   try {
  //     await _updateLoading(true);
  //     final fetchedProducts = await apiServices.fetchProducts(
  //       searchQuery: searchQuery,
  //       selectedCategories: selectedCategories,
  //       selectedLocations: selectedLocations,
  //     );
  //     print(
  //       'Fetched products: ${fetchedProducts.map((p) => {'id': p.id, 'name': p.productName, 'isActive': p.isActive}).toList()}',
  //     );
  //     products.assignAll(fetchedProducts);
  //     await _cacheProducts(fetchedProducts);
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_fetch_products'.trParams({
  //       'error': e.toString(),
  //     });
  //     Get.snackbar(
  //       'error'.tr,
  //       errorMessage.value,
  //       backgroundColor: Colors.red.shade100,
  //     );
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }

  // Future<void> _cacheProducts(List<Product> products) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final productsJson = products.map((p) => jsonEncode(p.toJson())).toList();
  //   await prefs.setStringList('products', productsJson);
  // }

  // Future<void> addProduct({
  //   required String productName,
  //   required File image,
  //   required String rate,
  //   required String availableQuantity,
  //   required String category,
  //   required String emailOrPhone,
  //   String? description,
  //   String unit = 'kg',
  //   double latitude = 0,
  //   double longitude = 0,
  // }) async {
  //   try {
  //     await _updateLoading(true);
  //     if (productName.length > 50) {
  //       throw Exception('Product name must be 50 characters or less');
  //     }
  //     if (category.length > 50) {
  //       throw Exception('Category must be 50 characters or less');
  //     }
  //     if (description != null && description.length > 300) {
  //       throw Exception('Description must be 300 characters or less');
  //     }
  //     final rateValue = double.tryParse(rate);
  //     final quantityValue = double.tryParse(availableQuantity);
  //     if (rateValue == null || rateValue < 0 || rateValue > 99999.99) {
  //       throw Exception('Rate must be between 0 and 99999.99');
  //     }
  //     if (quantityValue == null ||
  //         quantityValue < 1 ||
  //         quantityValue > 99999.99) {
  //       throw Exception('Available quantity must be between 1 and 99999.99');
  //     }

  //     final newProduct = await apiServices.addProduct(
  //       productName: productName,
  //       image: image,
  //       rate: rate,
  //       availableQuantity: availableQuantity,
  //       category: category,
  //       emailOrPhone: emailOrPhone,
  //       unit: unit,
  //       description: description?.isNotEmpty == true ? description : null,
  //       latitude: latitude,
  //       longitude: longitude,
  //     );
  //     products.insert(0, newProduct);
  //     products.refresh();
  //     PopupService.success(
  //       'product_added'.trParams({'name': newProduct.productName}),
  //     );
  //     await fetchProducts();
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_add_product'.trParams({
  //       'error': e.toString(),
  //     });
  //     PopupService.error(errorMessage.value);
  //     debugPrint('Error in addProduct: $e');
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }

  // // Old addProduct method (commented out for reference)
  // /*
  // Future<void> addProduct({
  //   required String productName,
  //   required File image,
  //   required String rate,
  //   required String availableQuantity,
  //   required String category,
  //   required String location,
  //   required String emailOrPhone,
  //   String? description,
  //   String unit = 'kg',
  // }) async {
  //   try {
  //     await _updateLoading(true);
  //     final newProduct = await apiServices.addProduct(
  //       productName: productName,
  //       image: image,
  //       rate: rate,
  //       availableQuantity: availableQuantity,
  //       category: category,
  //       location: location,
  //       emailOrPhone: emailOrPhone,
  //       unit: unit,
  //       description: description?.isNotEmpty == true ? description : null,
  //     );
  //     products.insert(0, newProduct);
  //     products.refresh();
  //     Get.snackbar('success'.tr, 'product_added'.trParams({'name': newProduct.productName}),
  //         backgroundColor: Colors.green.shade100);
  //     await fetchProducts();
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_add_product'.trParams({'error': e.toString()});
  //     Get.snackbar('error'.tr, errorMessage.value, backgroundColor: Colors.red.shade100);
  //     rethrow;
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }
  // */

  // // Future<void> updateProduct(
  // //   String productId,
  // //   String productName,
  // //   File? image,
  // //   String rate,
  // //   String availableQuantity,
  // //   String category,
  // //   String unit,
  // //   String? description,
  // //   double latitude,
  // //   double longitude,
  // // ) async {
  // //   try {
  // //     await _updateLoading(true);
  // //     if (productName.length > 50) {
  // //       throw Exception('Product name must be 50 characters or less');
  // //     }
  // //     if (category.length > 50) {
  // //       throw Exception('Category must be 50 characters or less');
  // //     }
  // //     if (description != null && description.length > 300) {
  // //       throw Exception('Description must be 300 characters or less');
  // //     }
  // //     final rateValue = double.tryParse(rate);
  // //     final quantityValue = double.tryParse(availableQuantity);
  // //     if (rateValue == null || rateValue < 0 || rateValue > 99999.99) {
  // //       throw Exception('Rate must be between 0 and 99999.99');
  // //     }
  // //     if (quantityValue == null ||
  // //         quantityValue < 1 ||
  // //         quantityValue > 99999.99) {
  // //       throw Exception('Available quantity must be between 1 and 99999.99');
  // //     }

  // //     final existingProduct = products.firstWhere((p) => p.id == productId);
  // //     final updatedProduct = await apiServices.updateProduct(
  // //       productId,
  // //       Product(
  // //         id: productId,
  // //         productName: productName,
  // //         rate: rateValue,
  // //         availableQuantity: quantityValue,
  // //         category: category,
  // //         unit: unit,
  // //         description: description ?? existingProduct.description,
  // //         image: existingProduct.image,
  // //         soldedQuantity: existingProduct.soldedQuantity,
  // //         farmerId: existingProduct.farmerId,
  // //         farmerName: existingProduct.farmerName,
  // //         farmerPhone: existingProduct.farmerPhone,
  // //         createdAt: existingProduct.createdAt,
  // //         isActive: existingProduct.isActive,
  // //         latitude: latitude,
  // //         longitude: longitude,
  // //       ),
  // //       imageFile: image,
  // //     );
  // //     final index = products.indexWhere((p) => p.id == productId);
  // //     if (index != -1) {
  // //       products[index] = updatedProduct;
  // //       products.refresh();
  // //     }
  // //     PopupService.success('product_updated'.tr);
  // //     await fetchProducts();
  // //   } catch (e) {
  // //     errorMessage.value = 'failed_to_update_product'.trParams({
  // //       'error': e.toString(),
  // //     });
  // //     PopupService.error(errorMessage.value);
  // //     rethrow;
  // //   } finally {
  // //     await _updateLoading(false);
  // //   }
  // // }

  // // Old updateProduct method (commented out for reference)
  // /*
  // Future<void> updateProduct(
  //   String productId,
  //   String productName,
  //   File? image,
  //   String rate,
  //   String availableQuantity,
  //   String category,
  //   String location,
  //   String unit,
  //   String? description,
  // ) async {
  //   try {
  //     await _updateLoading(true);
  //     final existingProduct = products.firstWhere((p) => p.id == productId);
  //     final updatedProduct = await apiServices.updateProduct(
  //       productId,
  //       Product(
  //         id: productId,
  //         productName: productName,
  //         rate: double.parse(rate),
  //         availableQuantity: double.parse(availableQuantity),
  //         category: category,
  //         location: location,
  //         unit: unit,
  //         description: description ?? existingProduct.description,
  //         image: existingProduct.image,
  //         soldedQuantity: existingProduct.soldedQuantity,
  //         farmerId: existingProduct.farmerId,
  //         farmerName: existingProduct.farmerName,
  //         farmerPhone: existingProduct.farmerPhone,
  //         createdAt: existingProduct.createdAt,
  //         isActive: existingProduct.isActive,
  //       ),
  //       imageFile: image,
  //     );
  //     final index = products.indexWhere((p) => p.id == productId);
  //     if (index != -1) {
  //       products[index] = updatedProduct;
  //       products.refresh();
  //     }
  //     Get.snackbar('success'.tr, 'product_updated'.tr, backgroundColor: Colors.green.shade100);
  //     await fetchProducts();
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_update_product'.trParams({'error': e.toString()});
  //     Get.snackbar('error'.tr, errorMessage.value, backgroundColor: Colors.red.shade100);
  //     rethrow;
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }
  // */

  // Future<void> deleteProduct(String productId) async {
  //   try {
  //     await _updateLoading(true);
  //     await apiServices.deleteProduct(productId);
  //     products.removeWhere((p) => p.id == productId);
  //     products.refresh();
  //     Get.snackbar(
  //       'success'.tr,
  //       'product_deleted'.tr,
  //       backgroundColor: Colors.green.shade100,
  //     );
  //     await fetchProducts();
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_delete_product'.trParams({
  //       'error': e.toString(),
  //     });
  //     Get.snackbar(
  //       'error'.tr,
  //       errorMessage.value,
  //       backgroundColor: Colors.red.shade100,
  //     );
  //     rethrow;
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }

  // Future<void> updateProductActiveStatus(
  //   String productId,
  //   bool isActive,
  // ) async {
  //   try {
  //     await _updateLoading(true);
  //     await apiServices.updateProductActiveStatus(productId, isActive);
  //     final index = products.indexWhere((p) => p.id == productId);
  //     if (index != -1) {
  //       products[index] = products[index].copyWith(isActive: isActive);
  //       products.refresh();
  //     }
  //     Get.snackbar(
  //       'success'.tr,
  //       'product_status_updated'.tr,
  //       backgroundColor: Colors.green.shade100,
  //     );
  //     await fetchProducts();
  //   } catch (e) {
  //     errorMessage.value = 'failed_to_update_status'.trParams({
  //       'error': e.toString(),
  //     });
  //     Get.snackbar(
  //       'error'.tr,
  //       errorMessage.value,
  //       backgroundColor: Colors.red.shade100,
  //     );
  //     rethrow;
  //   } finally {
  //     await _updateLoading(false);
  //   }
  // }

  Future<void> fetchTutorials() async {
    try {
      await _updateLoading(true);
      final fetchedTutorials = await apiServices.fetchTutorials();
      tutorials.assignAll(fetchedTutorials);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_tutorials'.trParams({
        'error': e.toString(),
      });
      // Get.snackbar(
      //   'error'.tr,
      //   errorMessage.value,
      //   backgroundColor: Colors.red.shade100,
      // );
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> fetchCrops() async {
    try {
      await _updateLoading(true);
      final fetchedCrops = await apiServices.fetchCrops();
      crops.assignAll(fetchedCrops);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_crops'.trParams({
        'error': e.toString(),
      });
      // Get.snackbar(
      //   'error'.tr,
      //   errorMessage.value,
      //   backgroundColor: Colors.red.shade100,
      // );
    } finally {
      await _updateLoading(false);
    }
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
      final newCrop = await apiServices.addCrop(
        cropName: cropName,
        area: area,
        plantingDate: plantingDate,
        location:
            location, //todo ADD THE  //TODO ADD THE LONGITUDE ADN THE LATUTUDE INSTEAD OF THE LOCATION STRING
        emailOrPhone: emailOrPhone,
        description: description,
      );
      crops.add(newCrop);
      crops.refresh();
      Get.snackbar(
        'success'.tr,
        'crop_added'.tr,
        backgroundColor: Colors.green.shade100,
      );
      await fetchCrops();
    } catch (e) {
      errorMessage.value = 'failed_to_add_crop'.trParams({
        'error': e.toString(),
      });
      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
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
      final updatedCrop = await apiServices.updateCrop(
        cropId,
        CropModel(
          id: cropId,
          description: description,
          name: cropName,
          // Add other required fields based on CropModel
        ),
      );
      final index = crops.indexWhere((c) => c.id == cropId);
      if (index != -1) {
        crops[index] = updatedCrop;
        crops.refresh();
      }
      Get.snackbar(
        'success'.tr,
        'crop_updated'.tr,
        backgroundColor: Colors.green.shade100,
      );
      await fetchCrops();
    } catch (e) {
      errorMessage.value = 'failed_to_update_crop'.trParams({
        'error': e.toString(),
      });
      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> deleteCrop(String cropId) async {
    try {
      await _updateLoading(true);
      await apiServices.deleteCrop(cropId);
      crops.removeWhere((c) => c.id == cropId);
      crops.refresh();
      Get.snackbar(
        'success'.tr,
        'crop_deleted'.tr,
        backgroundColor: Colors.green.shade100,
      );
      await fetchCrops();
    } catch (e) {
      errorMessage.value = 'failed_to_delete_crop'.trParams({
        'error': e.toString(),
      });
      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> fetchOrders() async {
    try {
      await _updateLoading(true);
      final fetchedOrders = await apiServices.fetchOrders();
      orders.assignAll(fetchedOrders);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_orders'.trParams({
        'error': e.toString(),
      });
      //TODO Get.snackbar(
      //   'error'.tr,
      //   errorMessage.value,
      //   backgroundColor: Colors.red.shade100,
      // );
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> fetchNotifications() async {
    try {
      await _updateLoading(true);
      final fetchedNotifications = await apiServices.fetchNotifications();
      notifications.assignAll(fetchedNotifications);
    } catch (e) {
      errorMessage.value = 'failed_to_fetch_notifications'.trParams({
        'error': e.toString(),
      });
      // Get.snackbar(
      //   'error'.tr,
      //   errorMessage.value,
      //   backgroundColor: Colors.red.shade100,
      // );
    } finally {
      await _updateLoading(false);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _updateLoading(true);
      await apiServices.markNotificationAsRead(notificationId);
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifications.refresh();
      }
      Get.snackbar(
        'success'.tr,
        'notification_marked_read'.tr,
        backgroundColor: Colors.green.shade100,
      );
      await fetchNotifications();
    } catch (e) {
      errorMessage.value = 'failed_to_mark_notification'.trParams({
        'error': e.toString(),
      });
      Get.snackbar(
        'error'.tr,
        errorMessage.value,
        backgroundColor: Colors.red.shade100,
      );
      rethrow;
    } finally {
      await _updateLoading(false);
    }
  }

  // Future<void> addProductFromForm(
  //   ProductFormData formData,
  //   String? imagePath,
  // ) async {
  //   final authController = Get.find<AuthController>();
  //   final emailOrPhone =
  //       authController.currentUser.value?.email ??
  //       authController.currentUser.value?.phoneNumber ??
  //       '';
  //   if (emailOrPhone.isEmpty) {
  //     PopupService.error('user_not_authenticated'.tr);
  //     return;
  //   }
  //   await addProduct(
  //     productName: formData.productName,
  //     image: imagePath != null ? File(imagePath) : File(''),
  //     rate: formData.rate.toString(),
  //     availableQuantity: formData.availableQuantity.toString(),
  //     category: formData.category,
  //     emailOrPhone: emailOrPhone,
  //     unit: formData.unit,
  //     description:
  //         formData.description.isNotEmpty ? formData.description : null,
  //     latitude: formData.latitude,
  //     longitude: formData.longitude,
  //   );
  // }

  // Future<void> updateProductFromForm(
  //   String productId,
  //   ProductFormData formData,
  //   String? imagePath,
  // ) async {
  //   //   await updateProduct(
  //   //     productId,
  //   //     formData.productName,
  //   //     imagePath != null ? File(imagePath) : null,
  //   //     formData.rate.toString(),
  //   //     formData.availableQuantity.toString(),
  //   //     formData.category,
  //   //     formData.unit,
  //   //     formData.description.isNotEmpty ? formData.description : null,

  //   //     formData.latitude,
  //   //     formData.longitude,
  //   //   );
  // }
}
