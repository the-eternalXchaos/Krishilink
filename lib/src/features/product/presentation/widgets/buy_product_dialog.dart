import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/product/data/models/product_model.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';
import 'package:krishi_link/src/features/cart/models/cart_item.dart';

class BuyProductDialog extends StatelessWidget {
  final Product? product;
  final dynamic singleItem; // backward compat (CartItem)
  BuyProductDialog({super.key, this.product, this.singleItem});
  final ProductController controller = Get.find<ProductController>();
  final CartController cartController =
      Get.isRegistered<CartController>()
          ? Get.find<CartController>()
          : Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(product?.productName ?? singleItem?.productName ?? 'Item'),
      content: Text('Rate: ${product?.rate ?? singleItem?.rate ?? '-'}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (product != null) {
              controller.addToCart(product!);
            } else if (singleItem is CartItem) {
              cartController.addToCart(singleItem as CartItem);
            }
            Navigator.pop(context);
          },
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
