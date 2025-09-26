import 'package:krishi_link/src/core/components/custom_drawer/custom_drawer.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:krishi_link/features/product/controllers/product_controller.dart';
// import 'package:krishi_link/src/core/components/bottom_sheet/app_bottom_sheet.dart';
//  // import 'package:krishi_link/core/utils/api_constants.dart';
// import 'package:krishi_link/features/cart/models/cart_item.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller_new.dart';
// import 'package:krishi_link/features/auth/controller/cart_controller.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/chat/live_chat/live_chat_screen.dart';
// import 'package:krishi_link/features/weather/weather_widget.dart';
// import 'package:krishi_link/services/popup_service.dart';
// import 'package:krishi_link/features/product/widgets/buy_product_dialog.dart';
// import 'package:krishi_link/widgets/related_products_widget.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';
// import 'package:krishi_link/features/chat/screens/product_chat_screen.dart';

// class ProductDetailPage extends StatefulWidget {
//   final Product product;
//   const ProductDetailPage({super.key, required this.product});

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   final ProductController _productController = Get.find<ProductController>();
//   final CartController cartController =
//       Get.isRegistered()
//           ? Get.find<CartController>()
//           : Get.put(CartController());
//   final AuthController authController = Get.find<AuthController>();
//   final TextEditingController reviewController = TextEditingController();
//   final RxBool isSubmittingReview = false.obs;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) => initializeData());
//   }

//   @override
//   void didUpdateWidget(ProductDetailPage oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.product.id != widget.product.id) {
//       WidgetsBinding.instance.addPostFrameCallback((_) => initializeData());
//     }
//   }

//   void initializeData() async {
//     await _productController.loadProductReviews(widget.product.id.toString());
//     _productController.fetchRelatedProducts(widget.product.id);
//   }

//   Future<void> shareProduct({
//     required String name,
//     required String description,
//     required String imageUrl,
//     required String productId,
//   }) async {
//     try {
//       final productUrl = 'https://krishilink.shamir.com.np/product/$productId';

//       final text = '''
// 🛒 $name
// 📄 $description

// 🔗 $productUrl
// ''';

//       if (imageUrl.isEmpty) {
//         // user share plus
//         await Share.share(text, subject: 'KrishiLink | $name');
//         PopupService.success('Product shared successfully');
//         // user share plus
//         return;
//       }

//       final dio = Dio();
//       final tempDir = await getTemporaryDirectory();
//       final safeName = name
//           .replaceAll(RegExp(r'[^\w\s]+'), '')
//           .replaceAll(' ', '_');
//       final imagePath = '${tempDir.path}/$safeName.jpg';

//       final response = await dio.download(
//         imageUrl,
//         imagePath,
//         options: Options(responseType: ResponseType.bytes),
//       );

//       if (response.statusCode != 200) {
//         throw Exception(
//           'Image download failed with status: ${response.statusCode}',
//         );
//       }

//       await Share.shareXFiles(
//         // user share plus , instance , share x files
//         [XFile(imagePath)],
//         text: text,
//         subject: 'KrishiLink | $name',
//       );
//     } catch (e) {
//       debugPrint('❌ Share failed: $e');
//       PopupService.error('Failed to share product');
//     }
//   }

//   void addToCart() {
//     if (!authController.isLoggedIn) {
//       PopupService.info(
//         'please_login_to_add_to_cart'.tr,
//         title: 'login_required'.tr,
//       );
//       return;
//     }

//     cartController.addToCart(CartItem.fromProduct(widget.product, quantity: 1));
//   }

//   void buyNow() {
//     if (!authController.isLoggedIn) {
//       PopupService.info('please_login_to_buy'.tr, title: 'login_required'.tr);
//       return;
//     }

//     AppBottomSheet.show(
//       // backgroundColor:Theme. of(context).colorScheme.surface ,
//       child: BuyProductDialog(
//         singleItem: CartItem.fromProduct(widget.product, quantity: 1),
//       ),
//       initialChildSize: 0.8,
//     );
//   }

//   void openChat() {
//     if (!authController.isLoggedIn) {
//       PopupService.info('please_login_to_chat'.tr, title: 'login_required'.tr);
//       return;
//     }

//     Get.to(
//       () => ProductChatScreen(
//         productId: widget.product.id.toString(),
//         productName: widget.product.productName,
//         farmerName: widget.product.farmerName.toString(),
//         emailOrPhone: widget.product.farmerPhone.toString(),
//       ),
//     );
//   }

//   Future<void> submitReview() async {
//     if (!authController.isLoggedIn) {
//       PopupService.info(
//         'please_login_to_submit_review'.tr,
//         title: 'login_required'.tr,
//       );
//       return;
//     }

//     final reviewText = reviewController.text.trim();
//     if (reviewText.isEmpty ||
//         reviewText.length < 3 ||
//         reviewText.length > 500) {
//       PopupService.warning(
//         'review_length_error'.tr,
//         title: 'validation_error'.tr,
//       );
//       return;
//     }

//     isSubmittingReview.value = true;
//     try {
//       await _productController.submitReview(
//         productId: widget.product.id,
//         reviewText: reviewText,
//         username: authController.currentUser.value?.fullName ?? 'anonymous'.tr,
//       );
//       reviewController.clear();
//     } finally {
//       isSubmittingReview.value = false;
//     }
//   }

//   String getImage() {
//     return widget.product.image.isNotEmpty
//         ? widget.product.image
//         : 'https://via.placeholder.com/250';
//   }

//   @override
//   void dispose() {
//     reviewController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Handle chat button press
//           // navigate to product chat screen
//           Get.to(
//             () => LiveChatScreen(
//               productId: widget.product.id.toString(),
//               productName: widget.product.productName,
//               farmerName: widget.product.farmerName.toString(),
//               emailOrPhone: widget.product.farmerPhone.toString(),
//             ),
//           );

//           debugPrint('Chat button pressed');
//         },
//         tooltip: "chat_with_farmer".tr,
//         child: Icon(Icons.message),
//       ),
//       appBar: AppBar(
//         title: Text(widget.product.productName),
//         backgroundColor: colorScheme.primary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.only(bottom: 80),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CachedNetworkImage(
//               imageUrl: getImage(),
//               height: 250,
//               width: double.infinity,
//               fit: BoxFit.cover,
//               placeholder:
//                   (_, __) => const Center(child: CircularProgressIndicator()),
//               errorWidget:
//                   (_, __, ___) => Container(
//                     height: 250,
//                     color: Colors.grey[300],
//                     child: const Icon(Icons.image_not_supported),
//                   ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.product.productName,
//                     style: textTheme.headlineSmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),

//                   Text(
//                     'price_per_kg'.trArgs([widget.product.rate.toString()]),
//                     style: textTheme.titleLarge?.copyWith(color: Colors.green),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'description'.tr,
//                     style: textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     widget.product.description.isNotEmpty
//                         ? widget.product.description
//                         : 'no_description_available'.tr,
//                     style: textTheme.bodyMedium,
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: addToCart,
//                           icon: const Icon(Icons.add_shopping_cart_rounded),
//                           label: Text('add_to_cart'.tr),
//                           style: OutlinedButton.styleFrom(
//                             side: BorderSide(color: colorScheme.primary),
//                             foregroundColor: colorScheme.primary,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: buyNow,
//                           icon: const Icon(Icons.payment),
//                           label: Text('buy_now'.tr),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: colorScheme.primary,
//                             foregroundColor: colorScheme.onPrimary,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     children: [
//                       // Expanded(
//                       //   child: OutlinedButton.icon(
//                       //     onPressed: openChat,
//                       //     icon: const Icon(Icons.chat_bubble_outline),
//                       //     label: Text('Chat with Farmer'),
//                       //     style: OutlinedButton.styleFrom(
//                       //       foregroundColor: Colors.green,
//                       //       side: const BorderSide(color: Colors.green),
//                       // ),
//                       // ),
//                       // ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed:
//                               () => shareProduct(
//                                 description: widget.product.description,
//                                 imageUrl: getImage(),
//                                 name: widget.product.productName,
//                                 productId: widget.product.id.toString(),
//                               ),
//                           icon: const Icon(Icons.share),
//                           label: Text('share'.tr),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.blue,
//                             side: const BorderSide(color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                   RelatedProductsWidget(productId: widget.product.id),
//                   const SizedBox(height: 24),
//                   Text(
//                     'customer_reviews'.tr,
//                     style: textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Obx(() {
//                     if (_productController.isLoadingReviews.value) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (_productController.reviewsModel.isEmpty) {
//                       return Center(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           child: Column(
//                             children: [
//                               const Icon(
//                                 Icons.rate_review_outlined,
//                                 size: 48,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'no_reviews_yet'.tr,
//                                 style: const TextStyle(color: Colors.grey),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     }

//                     return ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _productController.reviewsModel.length,
//                       itemBuilder: (context, index) {
//                         final review = _productController.reviewsModel[index];
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     CircleAvatar(
//                                       child: Text(
//                                         review.username.isNotEmpty
//                                             ? review.username[0]
//                                             : '?',
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           review.username,
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         Text(
//                                           DateFormat(
//                                             'MMM dd, yyyy',
//                                           ).format(review.timestamp),
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.grey,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(review.review),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }),
//                   const SizedBox(height: 24),
//                   Card(
//                     margin: const EdgeInsets.only(top: 8),
//                     child: Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'contact_farmer'.tr,
//                             style: textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text('${'name'.tr}: ${widget.product.farmerName}'),
//                           Text('${'phone'.tr}: ${widget.product.farmerPhone}'),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             children: [
//               Expanded(
//                 child: TextField(
//                   controller: reviewController,
//                   decoration: InputDecoration(
//                     hintText: 'submit_your_review'.tr,
//                     filled: true,
//                     fillColor: colorScheme.surface,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(20),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Obx(
//                 () =>
//                     isSubmittingReview.value
//                         ? const CircularProgressIndicator()
//                         : IconButton(
//                           icon: Icon(Icons.send, color: colorScheme.primary),
//                           onPressed: submitReview,
//                         ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/buy_product_dialog.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
// import 'package:krishi_link/features/chat/live_chat/product_chat_screen.dart';
import 'package:krishi_link/features/product/widgets/related_products_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:krishi_link/src/core/components/bottom_sheet/app_bottom_sheet.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

import 'package:krishi_link/src/features/chat/presentation/screens/product_chat_screen.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductController _productController = Get.find<ProductController>();

  final AuthController authController = Get.find<AuthController>();

  final TextEditingController reviewController = TextEditingController();
  final RxBool isSubmittingReview = false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  @override
  void didUpdateWidget(covariant ProductDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
    }
  }

  Future<void> _initializeData() async {
    await _productController.loadProductReviews(widget.product.id.toString());
    _productController.fetchRelatedProducts(widget.product.id);
  }

  // ---- helpers ----
  String _imageUrlOrPlaceholder() {
    final img = widget.product.image;
    if (img.trim().isEmpty) {
      return 'https://via.placeholder.com/250';
    }
    return img.trim();
  }

  DateTime _asDateTime(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    return DateTime.now();
  }

  Future<void> _shareProduct({
    required String name,
    required String description,
    required String imageUrl,
    required String productId,
  }) async {
    try {
      final productUrl = 'https://krishilink.shamir.com.np/product/$productId';

      final text = '''
🛒 $name
📄 $description

🔗 $productUrl
''';

      // quick path: no image or invalid URL
      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
        await Share.share(text, subject: 'KrishiLink | $name');
        PopupService.showSnackbar(
          title: 'product_shared_successfully'.tr,
          message: 'check_your_share_options'.tr,
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final safeName = name
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final imagePath = '${tempDir.path}/$safeName.jpg';

      final response = await dio.download(
        imageUrl,
        imagePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Image download failed with status: ${response.statusCode}',
        );
      }

      await Share.shareXFiles(
        [XFile(imagePath, mimeType: 'image/jpeg')],
        text: text,
        subject: 'KrishiLink | $name',
      );

      PopupService.showSnackbar(
        title: 'success'.tr,
        message: 'product_shared_successfully'.tr,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ Share failed: $e\n$st');
      }
      PopupService.error('Failed to share product');
    }
  }

  void _addToCart() {
    if (!authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_add_to_cart'.tr,
        title: 'login_required'.tr,
      );
      return;
    }
    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());
    cartController.addToCart(CartItem.fromProduct(widget.product, quantity: 1));
  }

  void _buyNow() {
    if (!authController.isLoggedIn) {
      PopupService.info('please_login_to_buy'.tr, title: 'login_required'.tr);
      return;
    }
    AppBottomSheet.show(
      child: BuyProductDialog(
        singleItem: CartItem.fromProduct(widget.product, quantity: 1),
      ),
      initialChildSize: 0.8,
    );
  }

  void _openChat() {
    if (!authController.isLoggedIn) {
      PopupService.info('please_login_to_chat'.tr, title: 'login_required'.tr);
      return;
    }
    Get.to(
      () => ProductChatScreen(
        productId: widget.product.id.toString(),
        productName: widget.product.productName,
        farmerName: widget.product.farmerName?.toString() ?? '',
        emailOrPhone: widget.product.farmerPhone?.toString() ?? '',
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!authController.isLoggedIn) {
      PopupService.info(
        'please_login_to_submit_review'.tr,
        title: 'login_required'.tr,
      );
      return;
    }

    final reviewText = reviewController.text.trim();
    if (reviewText.isEmpty ||
        reviewText.length < 3 ||
        reviewText.length > 500) {
      PopupService.warning(
        'review_length_error'.tr,
        title: 'validation_error'.tr,
      );
      return;
    }

    isSubmittingReview.value = true;
    try {
      await _productController.submitReview(
        productId: widget.product.id,
        reviewText: reviewText,
        username: authController.currentUser.value?.fullName ?? 'anonymous'.tr,
      );
      reviewController.clear();
      PopupService.showSnackbar(
        title: 'review_submitted'.tr,
        message: 'thank_you_for_your_feedback'.tr,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ submitReview failed: $e\n$st');
      }
      PopupService.error('failed_to_submit_review'.tr);
    } finally {
      isSubmittingReview.value = false;
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChat,
        label: Text('chat_with_farmer'.tr),
        icon: const Icon(Icons.message),
        tooltip: 'chat_with_farmer'.tr,
      ),
      appBar: AppBar(
        title: Text(widget.product.productName),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeNetworkImage(
              imageUrl: _imageUrlOrPlaceholder(),
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorWidget: Container(
                height: 250,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.productName,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs ${widget.product.rate.toStringAsFixed(2)} / kg',
                    // Rs ${ widget.product.rate.toStringAsFixed(2),} kg
                    // 'price_per_kg'.trParams({
                    //   '%s': widget.product.rate.toStringAsFixed(2),
                    // }),
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'description'.tr,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.trim().isNotEmpty
                        ? widget.product.description.trim()
                        : 'no_description_available'.tr,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // ---- actions row ----
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          label: Text('add_to_cart'.tr),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.primary),
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _buyNow,
                          icon: const Icon(Icons.payment),
                          label: Text('buy_now'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              () => _shareProduct(
                                description: widget.product.description,
                                imageUrl: _imageUrlOrPlaceholder(),
                                name: widget.product.productName,
                                productId: widget.product.id.toString(),
                              ),
                          icon: const Icon(Icons.share),
                          label: Text('share'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _productController.relatedProducts.isNotEmpty
                      ? RelatedProductsWidget(productId: widget.product.id)
                      : const SizedBox.shrink(),

                  const SizedBox(height: 24),
                  Text(
                    'customer_reviews'.tr,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Obx(() {
                    if (_productController.isLoadingReviews.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (_productController.reviewsModel.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.rate_review_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'no_reviews_yet'.tr,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _productController.reviewsModel.length,
                      itemBuilder: (context, index) {
                        final review = _productController.reviewsModel[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                        (review.username.isNotEmpty
                                                ? review.username[0]
                                                : '?')
                                            .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(
                                            _asDateTime(review.timestamp),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(review.review),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  const SizedBox(height: 24),
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'contact_farmer'.tr,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${'name'.tr}: ${widget.product.farmerName ?? '-'}',
                          ),
                          Text(
                            '${'phone'.tr}: ${widget.product.farmerPhone ?? '-'}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ---- persistent review input bar ----
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: reviewController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitReview(),
                  decoration: InputDecoration(
                    hintText: 'submit_your_review'.tr,
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () =>
                    isSubmittingReview.value
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          icon: Icon(Icons.send, color: colorScheme.primary),
                          onPressed: _submitReview,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
