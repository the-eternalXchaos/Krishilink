import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/filter_controller.dart';
import 'package:krishi_link/src/features/product/presentation/controllers/product_controller.dart';

import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/ai_chat/ai_chat_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/features/buyer/screens/buyer_menu_page.dart';
import 'package:krishi_link/features/buyer/screens/cart_screen.dart';
import 'package:krishi_link/features/chat/screens/chat_list_screen.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/product_grid.dart';
import 'package:krishi_link/src/features/product/presentation/widgets/search_bar.dart'
    as custom;
// import 'package:krishi_link/src/core/customappbar/custom_app_bar.dart';
import 'package:krishi_link/core/widgets/custom_app_bar.dart';

import 'package:lottie/lottie.dart';

class BuyerHomePage extends StatefulWidget {
  final bool isGuest;
  const BuyerHomePage({super.key, this.isGuest = true});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  // Controllers
  late final AuthController authController;
  CartController? cartController;
  WishlistController? wishlistController;
  late final ProductController productController;
  late final FilterController filterController;

  @override
  void initState() {
    super.initState();

    // init controllers safely
    authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());

    if (authController.isLoggedIn) {
      cartController =
          Get.isRegistered<CartController>()
              ? Get.find<CartController>()
              : Get.put(CartController());
      wishlistController =
          Get.isRegistered<WishlistController>()
              ? Get.find<WishlistController>()
              : Get.put(WishlistController());
    }
    productController =
        Get.isRegistered<ProductController>()
            ? Get.find<ProductController>()
            : Get.put(ProductController(), permanent: true);
    filterController =
        Get.isRegistered<FilterController>()
            ? Get.find<FilterController>()
            : Get.put(FilterController());

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  Future<void> _initializeData() async {
    try {
      // Only fetch if products are empty or very old (cache for 5 minutes)
      final shouldFetch =
          productController.products.isEmpty ||
          productController.lastSuccessfulFetch == null ||
          DateTime.now().difference(productController.lastSuccessfulFetch!) >
              const Duration(minutes: 5);

      if (shouldFetch) {
        await productController.fetchProducts();
      }
      // FilterController now fetches initial data on its own init.

      if (_searchController.text.trim().isEmpty) {
        filterController.clearFilters();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  void _onTabTapped(int index) {
    if ((index == 1 || index == 2 || index == 3) &&
        !authController.isLoggedIn) {
      PopupService.warning(
        'please_login_to_access_menu'.tr,
        title: 'login_required'.tr,
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLoginRequiredScreen(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 100, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to access $title.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const LoginScreen()),
              icon: const Icon(Icons.login),
              label: Text('login'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Semantics(
            label: 'App bar',
            child: CustomAppBar(isGuest: !authController.isLoggedIn),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'search_products'.tr,
            child: const custom.SearchBar(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return Center(
                  child: Lottie.asset(AssetPaths.productLoading, repeat: false),
                );
              }

              if (productController.filteredProducts.isEmpty) {
                return Center(
                  child: RefreshIndicator.adaptive(
                    onRefresh: () => productController.fetchProducts(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // lottie error
                          Lottie.asset(
                            LottieAssets.notAvailable,
                            height: 250,
                            repeat: true,
                          ),
                          Text(
                            'no_products_found'.tr,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: productController.fetchProducts,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('retry'.tr),
                                const SizedBox(width: 8),
                                const Icon(Icons.refresh),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: RefreshIndicator.adaptive(
                  onRefresh: () => productController.fetchProducts(),
                  child: ProductGrid(
                    key: ValueKey(
                      '${productController.filteredProducts.length}_${filterController.productSearchQuery}',
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(),
            !authController.isLoggedIn
                ? _buildLoginRequiredScreen("menu".tr)
                : const BuyerMenuPage(),
          ],
        ),
      ),
      floatingActionButton:
          !authController.isLoggedIn
              ? null
              : Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Stack(
                      children: [
                        FloatingActionButton(
                          heroTag: 'cart_fab',
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          onPressed: () {
                            debugPrint(
                              '🛒 [BuyerHomePage] 🚀 Cart FAB pressed - Navigating to CartScreen...',
                            );
                            debugPrint(
                              '🛒 [BuyerHomePage] 🛍️ Current cart items: ${cartController?.cartItems.length ?? 0}',
                            );
                            Get.to(() => CartScreen());
                          },
                          tooltip: 'cart'.tr,
                          child: const Icon(Icons.local_grocery_store_rounded),
                        ),
                        if (cartController != null &&
                            cartController!.cartItems.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cartController!.cartItems.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (authController.currentUser.value?.role.toLowerCase() ==
                        'farmer'.toLowerCase())
                      FloatingActionButton(
                        heroTag: 'chat_ai',
                        backgroundColor: Colors.deepPurple,
                        tooltip: 'Chat with AI',
                        child: const Icon(Icons.smart_toy, color: Colors.white),
                        onPressed:
                            () => Get.to(
                              () => AiChatScreen(
                                name:
                                    authController.currentUser.value!.fullName,
                              ),
                            ),
                      ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.surfaceContainer,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withAlpha(150),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'home'.tr,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'menu'.tr),
        ],
      ),
    );
  }
}
