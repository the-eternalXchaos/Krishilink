import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/controllers/filter_controller.dart';
import 'package:krishi_link/controllers/product_controller.dart';
import 'package:krishi_link/core/components/material_ui/popUp.dart';
import 'package:krishi_link/core/components/material_ui/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/ai_chat/ai_chat_screen.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/auth/controller/cart_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/buyer/controllers/wishlist_controller.dart';
import 'package:krishi_link/features/buyer/screens/buyer_menu_page.dart';
import 'package:krishi_link/features/buyer/screens/cart_screen.dart';
import 'package:krishi_link/services/popup_service.dart';
import 'package:krishi_link/widgets/custom_app_bar.dart';
import 'package:krishi_link/widgets/product_grid.dart';
import 'package:krishi_link/widgets/search_bar.dart' as custom;
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
  Timer? _debounce;
  final authController = Get.find<AuthController>();
  // final isGuest = authController.isLoggedIn;

  final CartController cartController =
      Get.isRegistered<CartController>()
          ? Get.find<CartController>()
          : Get.put(CartController());
  final WishlistController wishlistController =
      Get.isRegistered<WishlistController>()
          ? Get.find<WishlistController>()
          : Get.put(WishlistController());
  final ProductController productController =
      Get.isRegistered<ProductController>()
          ? Get.find<ProductController>()
          : Get.put(ProductController());
  final FilterController filterController =
      Get.isRegistered<FilterController>()
          ? Get.find<FilterController>()
          : Get.put(FilterController());

  @override
  void initState() {
    super.initState();
    // Fetch all products at once for in-app filtering
    productController.fetchProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
    if (_searchController.text.trim().isEmpty) {
      filterController.clearFilters();
      return;
    }
  }

  Future<void> _initializeData() async {
    await productController.fetchProducts();
    await filterController.loadInitialData();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      filterController.searchProducts(query);
      // In-app filtering will update filteredProducts
    });
  }

  void _onTabTapped(int index) {
    if ((index == 1 || index == 2) && !authController.isLoggedIn) {
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
    _debounce?.cancel();
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
            child: custom.SearchBar(
              searchController: _searchController,
              onSearch: (_) => _onSearchChanged(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return Center(
                  child: Lottie.asset(productLoading, repeat: false),
                );
              }

              if (productController.filteredProducts.isEmpty) {
                return Center(
                  child: Text(
                    'no_products_found'.tr,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ProductGrid(
                  key: ValueKey(
                    '${productController.filteredProducts.length}_${filterController.productSearchQuery}',
                  ),
                  products: productController.filteredProducts,
                  controller: productController,
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
            // widget.isGuest
            //     ? _buildLoginRequiredScreen("Cart")
            //     : const CartScreen(),
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
                          onPressed: () => Get.to(() => CartScreen()),
                          tooltip: 'cart'.tr,
                          child: const Icon(Icons.local_grocery_store_rounded),
                        ),
                        if (cartController.cartItems.isNotEmpty)
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
                                '${cartController.cartItems.length}',
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
                    FloatingActionButton(
                      heroTag: 'chat_ai',
                      backgroundColor: Colors.deepPurple,
                      tooltip: 'Chat with AI',
                      child: const Icon(Icons.smart_toy, color: Colors.white),
                      onPressed:
                          () => Get.to(
                            () => AiChatScreen(
                              name: authController.currentUser.value!.fullName,
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
