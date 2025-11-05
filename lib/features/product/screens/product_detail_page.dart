import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/product/widgets/related_products_widget.dart';
import 'package:krishi_link/features/product/widgets/review_card.dart';
import 'package:krishi_link/src/core/components/bottom_sheet/app_bottom_sheet.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/core/networking/dio_provider.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';
import 'package:krishi_link/src/features/chat/presentation/screens/product_chat_screen.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/buy_product_dialog.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  final ProductController _productController = Get.find<ProductController>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController reviewController = TextEditingController();
  final RxBool isSubmittingReview = false.obs;
  final ScrollController _scrollController = ScrollController();
  final RxBool isScrolled = false.obs;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !isScrolled.value) {
      isScrolled.value = true;
      _fabAnimController.forward();
    } else if (_scrollController.offset <= 100 && isScrolled.value) {
      isScrolled.value = false;
      _fabAnimController.reverse();
    }
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

  String _imageUrlOrPlaceholder() {
    final img = widget.product.image;
    if (img.trim().isEmpty) {
      return 'https://via.placeholder.com/250';
    }
    return img.trim();
  }

  void _showDeleteConfirmation(BuildContext context, review) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red[400]),
                const SizedBox(width: 8),
                const Text('Delete Review'),
              ],
            ),
            content: const Text('Are you sure you want to delete this review?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (review.id != null && review.id!.isNotEmpty) {
                    await _productController.deleteReview(review.id!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Cannot delete review: Invalid review ID',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showEditReviewDialog(BuildContext context, review) {
    final reviewText = (review.review as String).obs;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Edit Review'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => TextField(
                    controller: TextEditingController(text: reviewText.value)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: reviewText.value.length),
                      ),
                    onChanged: (value) => reviewText.value = value,
                    decoration: InputDecoration(
                      hintText: 'Enter your review',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                      filled: true,
                    ),
                    maxLength: 200,
                    maxLines: 4,
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${reviewText.value.length}/200',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            reviewText.value.length > 200
                                ? Colors.red
                                : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newText = reviewText.value.trim();
                  Navigator.pop(dialogContext);

                  if (review.id != null && review.id!.isNotEmpty) {
                    await _productController.updateReview(review.id!, newText);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cannot update review: Invalid review ID',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showReportDialog(BuildContext context, review) {
    final TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.flag_outlined, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text('Report Review'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Why are you reporting this review?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reportController,
                  decoration: InputDecoration(
                    hintText: 'Enter reason (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  reportController.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review reported successfully'),
                    ),
                  );
                  reportController.dispose();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Report'),
              ),
            ],
          ),
    );
  }

  Future<void> _showFarmerStats(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final dioProvider = Get.find<DioProvider>();
      final response = await dioProvider.client.get(
        '${ApiConstants.farmerStatEndpoint}/${widget.product.id}',
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          _displayFarmerStatsModal(context, data);
        } else {
          PopupService.error('No farmer information available');
        }
      } else {
        PopupService.error('Failed to load farmer information');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      debugPrint('[FarmerStats] Error: $e');
      PopupService.error('Error loading farmer information: ${e.toString()}');
    }
  }

  void _displayFarmerStatsModal(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder:
                  (context, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withValues(
                                        alpha: 0.7,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: colorScheme.onPrimary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['fullName'] ?? 'Unknown Farmer',
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.secondaryContainer,
                                            colorScheme.secondaryContainer
                                                .withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data['reputation'] ?? 'New Grower',
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildInfoCard(
                            context,
                            icon: Icons.verified_user,
                            title: 'Record Status',
                            value: data['report'] ?? 'N/A',
                            color:
                                (data['report']?.toString().toLowerCase() ?? '')
                                        .contains('clean')
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          if (data['email'] != null ||
                              data['address'] != null) ...[
                            _buildSectionTitle(context, 'Contact Information'),
                            const SizedBox(height: 12),
                            if (data['email'] != null)
                              _buildInfoRow(
                                context,
                                Icons.email_outlined,
                                'Email',
                                data['email'],
                              ),
                            if (data['address'] != null)
                              _buildInfoRow(
                                context,
                                Icons.location_on_outlined,
                                'Address',
                                '${data['address']}, ${data['city'] ?? ''}',
                              ),
                            const SizedBox(height: 16),
                          ],
                          _buildSectionTitle(context, 'Sales Statistics'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Total Products',
                                  value: '${data['totalProducts'] ?? 0}',
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  icon: Icons.shopping_cart_outlined,
                                  label: 'Items Sold',
                                  value: '${data['totalProductSolded'] ?? 0}',
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            context,
                            icon: Icons.trending_up,
                            label: 'Avg. Quantity Sold',
                            value: (data['averageSoldedQuantity'] ?? 0.0)
                                .toStringAsFixed(1),
                            color: Colors.purple,
                            isWide: true,
                          ),
                          const SizedBox(height: 16),
                          if (data['maxSoldedProduct'] != null ||
                              data['minSoldedProduct'] != null) ...[
                            _buildSectionTitle(context, 'Product Performance'),
                            const SizedBox(height: 12),
                            if (data['maxSoldedProduct'] != null)
                              _buildProductPerformanceCard(
                                context,
                                icon: Icons.star,
                                title: 'Top Seller',
                                productName:
                                    data['maxSoldedProduct']['productName'] ??
                                    'N/A',
                                quantity:
                                    data['maxSoldedProduct']['soldedQuantity'] ??
                                    0,
                                color: Colors.amber,
                              ),
                            const SizedBox(height: 8),
                            if (data['minSoldedProduct'] != null)
                              _buildProductPerformanceCard(
                                context,
                                icon: Icons.trending_down,
                                title: 'Least Sold',
                                productName:
                                    data['minSoldedProduct']['productName'] ??
                                    'N/A',
                                quantity:
                                    data['minSoldedProduct']['soldedQuantity'] ??
                                    0,
                                color: Colors.grey,
                              ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isWide = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: isWide ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPerformanceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String productName,
    required num quantity,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  productName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$quantity sold',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    final cartController =
        Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : Get.put(CartController());

    if (authController.isLoggedIn) {
      cartController.addToCart(
        CartItem.fromProduct(widget.product, quantity: 1),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${'added_to_cart'.tr}: ${widget.product.productName}',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      PopupService.info(
        'please_login_to_add_to_cart'.tr,
        title: 'login_required'.tr,
      );
    }
  }

  void _buyNow() {
    if (!authController.isLoggedIn) {
      PopupService.info('please_login_to_buy'.tr, title: 'login_required'.tr);
      return;
    }
    AppBottomSheet.show(
      child: BuyProductDialog(product: widget.product),
      initialChildSize: 0.7,
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
        farmerId: widget.product.farmerId,
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
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('❌ submitReview failed: $e\n$st');
      }
    } finally {
      isSubmittingReview.value = false;
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    _scrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fabAnimController,
            curve: Curves.easeOutBack,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: _openChat,
          label: Text('chat_with_farmer'.tr),
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'chat_with_farmer'.tr,
          elevation: 4,
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern App Bar with transparent background
          Obx(
            () => SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor:
                  isScrolled.value ? colorScheme.surface : Colors.transparent,
              elevation: isScrolled.value ? 4 : 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () => _showFarmerStats(context),
                    tooltip: 'Farmer Info',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed:
                        () => _shareProduct(
                          description: widget.product.description,
                          imageUrl: _imageUrlOrPlaceholder(),
                          name: widget.product.productName,
                          productId: widget.product.id.toString(),
                        ),
                    tooltip: 'Share',
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(
                      imageUrl: _imageUrlOrPlaceholder(),
                      fit: BoxFit.cover,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info Card
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product.productName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Price Tag with modern design
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.product.rate.toStringAsFixed(2)} / kg',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'description'.tr,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.product.description.trim().isNotEmpty
                                    ? widget.product.description.trim()
                                    : 'no_description_available'.tr,
                                style: textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons - Modern Design
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addToCart,
                                icon: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                ),
                                label: Text('add_to_cart'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.surface,
                                  foregroundColor: colorScheme.primary,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // TODO remove it later  buy now
                            // Expanded(
                            //   child: ElevatedButton.icon(
                            //     onPressed: _buyNow,
                            //     icon: const Icon(Icons.shopping_bag_outlined),
                            //     label: Text('buy_now'.tr),
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: colorScheme.primary,
                            //       foregroundColor: colorScheme.onPrimary,
                            //       elevation: 2,
                            //       padding: const EdgeInsets.symmetric(
                            //         vertical: 16,
                            //       ),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(16),
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Farmer Contact Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.5,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.agriculture_outlined,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'contact_farmer'.tr,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                Icons.person_outline,
                                'name'.tr,
                                widget.product.farmerName ?? '-',
                              ),
                              const SizedBox(height: 8),
                              _buildContactRow(
                                Icons.phone_outlined,
                                'phone'.tr,
                                widget.product.farmerPhone ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Related Products Section
                  Obx(() {
                    if (_productController.relatedProducts.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.recommend_outlined,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Related Products',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            RelatedProductsWidget(productId: widget.product.id),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'customer_reviews'.tr,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Obx(() {
                          if (_productController.isLoadingReviews.value) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (_productController.reviewsModel.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.reviews_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'no_reviews_yet'.tr,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Be the first to review!',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                      ),
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
                              final review =
                                  _productController.reviewsModel[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReviewCard(
                                  review: review,
                                  currentUserId:
                                      authController.currentUser.value?.id,
                                  onEdit: () {
                                    _showEditReviewDialog(context, review);
                                  },
                                  onDelete: () {
                                    _showDeleteConfirmation(context, review);
                                  },
                                  onReport: () {
                                    _showReportDialog(context, review);
                                  },
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Modern Review Input Bar - Keyboard Aware
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: reviewController,
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _submitReview(),
                      decoration: InputDecoration(
                        hintText: 'submit_your_review'.tr,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.edit_outlined,
                          color: colorScheme.primary,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () =>
                      isSubmittingReview.value
                          ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                          : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: colorScheme.onPrimary,
                              ),
                              onPressed: _submitReview,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
