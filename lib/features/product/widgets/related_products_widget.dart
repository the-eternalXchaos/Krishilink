// Legacy shim
export 'package:krishi_link/src/features/product/presentation/widgets/related_products_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import '../../../src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/features/product/screens/product_detail_page.dart';

class RelatedProductsWidget extends StatefulWidget {
  final String productId;

  const RelatedProductsWidget({super.key, required this.productId});

  @override
  State<RelatedProductsWidget> createState() => _RelatedProductsWidgetState();
}

class _RelatedProductsWidgetState extends State<RelatedProductsWidget> {
  final productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        productController.fetchRelatedProducts(widget.productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (productController.isRelatedLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (productController.relatedErrorMessage.value.isNotEmpty) {
        return Center(
          child: Text(
            productController.relatedErrorMessage.value,
            style: const TextStyle(color: Colors.red),
          ),
        );
      }

      final relatedProducts =
          productController.relatedProducts
              .where((p) => p.id != widget.productId)
              .toList();

      if (relatedProducts.isEmpty) {
        return Center(child: Text('no_related_products_found'.tr));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'related_products'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: relatedProducts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return RelatedProductCard(
                  onTap: () {
                    debugPrint("Tapped on ${product.productName}");
                    // Get.off(() => ProductDetailPage(product: product));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(product: product),
                      ),
                    );
                  },

                  product: product,
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class RelatedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const RelatedProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,

      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SafeNetworkImage(
            imageUrl: product.image,
            fit: BoxFit.cover,
            height: 100,
            width: double.infinity,
            placeholder: Container(
              height: 100,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: Container(
              height: 100,
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
