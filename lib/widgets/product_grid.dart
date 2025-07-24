import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/controllers/product_controller.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/widgets/product_card.dart';
import 'package:krishi_link/widgets/product_detail_page.dart';

class ProductGrid extends StatelessWidget {
  final ProductController controller;

  const ProductGrid({
    super.key,
    required this.controller,
    required List<Product> products,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredProducts.isEmpty) {
        return GestureDetector(
          onTap: () {
            controller.fetchProducts(
              page: 1,
              pageSizeParam: 20,
              searchQuery: controller.filterController.productSearchQuery.value,
              selectedCategories:
                  controller.filterController.selectedCategories,
              selectedLocations: controller.filterController.selectedLocations,
              status: controller.filterController.selectedStatus.value,
              reset: true,
            );
          },
          child: Center(
            child: Text(
              'no_products_available'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.fetchProducts(
            page: 1,
            pageSizeParam: 20,
            searchQuery: controller.filterController.productSearchQuery.value,
            selectedCategories: controller.filterController.selectedCategories,
            selectedLocations: controller.filterController.selectedLocations,
            status: controller.filterController.selectedStatus.value,
            reset: true,
          );
        },
        child: GridView.builder(
          itemCount: controller.filteredProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62, // tweak this for better fit
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final product = controller.filteredProducts[index];
            return InkWell(
              onTap: () {
                debugPrint('Tapped on:  [32m${product.productName} [0m');
                Get.to(() => ProductDetailPage(product: product));
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.green.withAlpha(30),
              child: ProductCard(product: product),
            );
          },
        ),
      );
    });
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/controllers/product_controller.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/features/admin/models/cart_item.dart';
// import 'package:krishi_link/features/admin/models/product_model.dart';
// import 'package:krishi_link/features/auth/controller/cart_controller.dart';
// import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
// import 'package:krishi_link/widgets/product_detail_page.dart';

// class ProductGrid extends StatelessWidget {
//   final List<Product> products;
//   final ProductController controller;

//   const ProductGrid({
//     super.key,
//     required this.products,
//     required this.controller,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final CartController cartController =
//         Get.isRegistered<CartController>()
//             ? Get.find<CartController>()
//             : Get.put(CartController());
//     final WishlistController wishlistController =
//         Get.isRegistered<WishlistController>()
//             ? Get.find<WishlistController>()
//             : Get.put(WishlistController());

//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.7,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       itemCount: products.length,
//       itemBuilder: (context, index) {
//         final product = products[index];
//         return GestureDetector(
//           onTap: () => Get.to(() => ProductDetailPage(product: product)),
//           child: Card(
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     child:
//                         product.image.isEmpty
//                             ? Image.asset(
//                               plantPlaceholder,
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                             )
//                             : Image.network(
//                               product.image,
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                               errorBuilder:
//                                   (context, error, stackTrace) => Image.asset(
//                                     plantPlaceholder,
//                                     fit: BoxFit.cover,
//                                   ),
//                             ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         product.productName,
//                         style: Theme.of(context).textTheme.titleMedium
//                             ?.copyWith(fontWeight: FontWeight.bold),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         '₹${product.rate}/kg',
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: ElevatedButton.icon(
//                           onPressed: () {
//                             cartController.addToCart(
//                               CartItem.fromProduct(product, quantity: 1),
//                             );
//                           },
//                           icon: const Icon(Icons.add_shopping_cart, size: 16),
//                           label: Text('add_to_cart'.tr),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Theme.of(context).primaryColor,
//                             foregroundColor:
//                                 Theme.of(context).colorScheme.onPrimary,
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
