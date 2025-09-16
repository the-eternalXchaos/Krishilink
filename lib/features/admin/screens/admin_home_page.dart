import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/components/product/management/unified_product_controller.dart';
import 'package:krishi_link/features/admin/controllers/component_animation_controller.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/features/profile/profile_screen.dart';
import 'package:krishi_link/core/widgets/custom_app_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:krishi_link/core/constants/constants.dart';
import 'package:krishi_link/features/admin/controllers/admin_category_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_order_controller.dart';
import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isLoggedIn = authController.isLoggedIn;
    final user = authController.currentUser;

    // Admin role check
    if (!isLoggedIn || user.value?.role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
        PopupService.error(
          'admin_access_required'.tr,
          title: 'access_denied'.tr,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AdminUserController userController = Get.find<AdminUserController>();
    final UnifiedProductController productController =
        Get.find<UnifiedProductController>();
    final AdminOrderController orderController =
        Get.find<AdminOrderController>();
    final AdminCategoryController categoryController =
        Get.find<AdminCategoryController>();
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    // Trigger initial animations for visible components
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ComponentAnimationController>(tag: 'header')) {
        Get.find<ComponentAnimationController>(tag: 'header').animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'header');
      }
      if (Get.isRegistered<ComponentAnimationController>(tag: 'sales_chart')) {
        Get.find<ComponentAnimationController>(tag: 'sales_chart').animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'sales_chart');
      }
      if (Get.isRegistered<ComponentAnimationController>(tag: 'quick_stats')) {
        Get.find<ComponentAnimationController>(tag: 'quick_stats').animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'quick_stats');
      }
      if (Get.isRegistered<ComponentAnimationController>(
        tag: 'dashboard_metrics',
      )) {
        Get.find<ComponentAnimationController>(
          tag: 'dashboard_metrics',
        ).animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'dashboard_metrics');
      }
      if (Get.isRegistered<ComponentAnimationController>(
        tag: 'quick_actions',
      )) {
        Get.find<ComponentAnimationController>(tag: 'quick_actions').animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'quick_actions');
      }
      if (Get.isRegistered<ComponentAnimationController>(
        tag: 'recent_activities',
      )) {
        Get.find<ComponentAnimationController>(
          tag: 'recent_activities',
        ).animate();
      } else {
        Get.put(ComponentAnimationController(), tag: 'recent_activities');
      }

      // Other components animate via VisibilityDetector on scroll
    });

    return Scaffold(
      // appBar: CustomAppBar(isGuest: !isLoggedIn || user.value == null),
      bottomNavigationBar:
          isWideScreen
              ? null
              : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(context).colorScheme.onSurface,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'dashboard'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'users'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grass),
                    label: 'products'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'orders'.tr,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu),
                    label: 'menu'.tr,
                  ),
                ],
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Get.toNamed('/admin/dashboard');
                      break;
                    case 1:
                      Get.toNamed('/admin/users');
                      break;
                    case 2:
                      Get.toNamed('/admin/products');
                      break;
                    case 3:
                      Get.toNamed('/admin/orders');
                      break;
                    // user menu plus
                    // add  for the message box  , like chat box

                    case 4:
                      _showMenuBottomSheet(context);
                      break;
                    // user menu plus
                  }
                },
              ),
      body: Row(
        children: [
          if (isWideScreen) _buildMenuSidebar(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                    Colors.green.shade200.withAlpha(204),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      _buildSalesChart(context),
                      _buildQuickStats(
                        context,
                        userController,
                        productController,
                        orderController,
                      ),
                      _buildDashboardMetrics(
                        context,
                        userController,
                        productController,
                        orderController,
                        categoryController,
                      ),
                      _buildQuickActions(context),
                      _buildRecentActivities(context),
                      _buildProfileCard(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final controller =
          Get.isRegistered()
              ? Get.find<ComponentAnimationController>(tag: 'header')
              : Get.put(ComponentAnimationController(), tag: 'header');
      return VisibilityDetector(
        key: const Key('header'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.slowMiddle,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Lottie.asset(
                  //   farmerIllustration,
                  //   height: 120,
                  //   width: 120,
                  //   repeat: false,
                  //   animate: true,
                  //   frameRate: FrameRate(30),
                  // ),
                  Text(
                    'welcome_admin'.tr,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    'manage_agri_network'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSalesChart(BuildContext context) {
    final chartData = [
      _SalesData('Mon', 5),
      _SalesData('Tue', 8),
      _SalesData('Wed', 6),
      _SalesData('Thu', 10),
      _SalesData('Fri', 7),
      _SalesData('Sat', 12),
      _SalesData(
        'Sun',
        9,
      ), //TODO: REPLACING THIS to the original order data for the like view
    ];
    // final chartData = orderController.orders
    //     .asMap()
    //     .entries
    //     .map((e) => _SalesData('Day ${e.key + 1}', e.value.totalPrice))
    //     .toList();
    return Obx(() {
      final controller =
          Get.isRegistered()
              ? Get.find<ComponentAnimationController>(tag: 'sales_chart')
              : Get.put(ComponentAnimationController(), tag: 'sales_chart');
      return VisibilityDetector(
        key: const Key('sales-chart'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,

            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'weekly_sales'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SfCartesianChart(
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(
                            labelFormat: '{value}K',
                            title: AxisTitle(text: 'sales'.tr),
                          ),
                          series: <CartesianSeries<_SalesData, String>>[
                            LineSeries<_SalesData, String>(
                              dataSource: chartData,
                              xValueMapper: (_SalesData sales, _) => sales.day,
                              yValueMapper:
                                  (_SalesData sales, _) => sales.sales,
                              color: Theme.of(context).colorScheme.primary,
                              width: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickStats(
    BuildContext context,
    AdminUserController userController,
    UnifiedProductController productController,
    AdminOrderController orderController,
  ) {
    return Obx(() {
      final controller =
          Get.isRegistered()
              ? Get.find<ComponentAnimationController>(tag: 'quick_stats')
              : Get.put(ComponentAnimationController(), tag: 'quick_stats');
      return VisibilityDetector(
        key: const Key('quick-stats'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildStatCard(
                    context,
                    'pending_orders'.tr,
                    orderController.pendingOrders.toString(),
                    Icons.hourglass_empty,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  _buildStatCard(
                    context,
                    'new_users_today'.tr,
                    userController.newUsersToday.toString(),
                    Icons.person_add,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  _buildStatCard(
                    context,
                    'active_farmers'.tr,
                    // userController.activeFarmers.toString(), //TODO do actual signalr for determining active farmer
                    '0',
                    Icons.agriculture,
                    Theme.of(context).colorScheme.primary.withAlpha(140),
                  ),
                  _buildStatCard(
                    context,
                    'total_products'.tr,
                    productController.getProductStats()['total'].toString(),
                    Icons.grass,
                    Theme.of(context).colorScheme.primary.withAlpha(140),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDashboardMetrics(
    BuildContext context,
    AdminUserController userController,
    UnifiedProductController productController,
    AdminOrderController orderController,
    AdminCategoryController categoryController,
  ) {
    return Obx(() {
      final controller =
          Get.isRegistered<ComponentAnimationController>()
              ? Get.find<ComponentAnimationController>(tag: 'dashboard_metrics')
              : Get.put(ComponentAnimationController( ));
      return VisibilityDetector(
        key: const Key('dashboard-metrics'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildMetricCard(
                    context,
                    'users'.tr,
                    userController.totalUsers.toString(),
                    Icons.people,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  _buildMetricCard(
                    context,
                    'products'.tr,
                    productController.getProductStats()['total'].toString(),
                    Icons.grass,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  _buildMetricCard(
                    context,
                    'categories'.tr,
                    categoryController.totalCategories.toString(),
                    Icons.category,
                    Theme.of(context).colorScheme.secondary,
                  ),
                  _buildMetricCard(
                    context,
                    'orders'.tr,
                    orderController.totalOrders.toString(),
                    Icons.shopping_cart,
                    Theme.of(context).colorScheme.primary.withAlpha(200),
                  ),
                  _buildMetricCard(
                    context,
                    'revenue'.tr,
                    'Rs ${orderController.totalRevenue.value.toStringAsFixed(0)}',
                    Icons.monetization_on,
                    Theme.of(context).colorScheme.primary.withAlpha(200),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickActions(BuildContext context) {
    return Obx(() {
      final controller =
          Get.isRegistered<ComponentAnimationController>(tag: 'quick_actions')
              ? Get.find<ComponentAnimationController>(tag: 'quick_actions')
              : Get.put(ComponentAnimationController(), tag: 'quick_actions');
      return VisibilityDetector(
        key: const Key('quick-actions'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'quick_actions'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        'manage_users'.tr,
                        Icons.person_add,
                        () => Get.toNamed('/admin/users'),
                      ),
                      _buildActionButton(
                        context,
                        'manage_products'.tr,
                        Icons.add_circle,
                        () => Get.toNamed('/admin/products'),
                      ),
                      _buildActionButton(
                        context,
                        'view_orders'.tr,
                        Icons.shopping_cart,
                        () => Get.toNamed('/admin/orders'),
                      ),
                      _buildActionButton(
                        context,
                        'marketplace'.tr,
                        Icons.store,
                        () => Get.toNamed('/admin/marketplace'),
                      ),
                      _buildActionButton(
                        context,
                        'manage_categories'.tr,
                        Icons.category,
                        () => Get.toNamed('/admin/categories'),
                      ),
                      _buildActionButton(
                        context,
                        'reports'.tr,
                        Icons.bar_chart,
                        () => Get.toNamed('/admin/reports'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecentActivities(BuildContext context) {
    final activities = [
      {
        'user': 'Ram Bahadur',
        'action': 'Added product: Rice',
        'time': '2h ago',
      },
      {
        'user': 'Sita Kumari',
        'action': 'Requested approval: Wheat',
        'time': '4h ago',
      },
      {'user': 'Hari Prasad', 'action': 'Updated profile', 'time': 'Yesterday'},
      {
        'user': 'Gopal Sharma',
        'action': 'Placed order: Tomatoes',
        'time': '2d ago',
      },
    ];

    return Obx(() {
      final controller =
          Get.isRegistered()
              ? Get.find<ComponentAnimationController>(tag: 'recent_activities')
              : Get.put(
                ComponentAnimationController(),
                tag: 'recent_activities',
              );
      return VisibilityDetector(
        key: const Key('recent-activities'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'recent_activities'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              activity['user']![0],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            activity['action']!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            activity['time']!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () {
                            PopupService.info(
                              '${activity['action']} ${'tapped'.tr}',
                              title: 'activity'.tr,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildProfileCard(BuildContext context) {
    return Obx(() {
      final controller = 
       Get.isRegistered() ?Get.find<ComponentAnimationController>(
        tag: 'profile_card',
      ) :Get.put(ComponentAnimationController(),  tag: 'profile_card',);
      return VisibilityDetector(
        key: const Key('profile-card'),
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5) {
            controller.animate();
          } else if (info.visibleFraction < 0.1) {
            controller.reset();
          }
        },
        child: AnimatedOpacity(
          opacity: controller.isVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: ScaleTransition(
            scale: controller.animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin_profile'.tr,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        final authController = Get.find<AuthController>();
                        final user = authController.currentUser.value;
                        return ListTile(
                          onTap: () => Get.to(() => ProfileScreen()),
                          // onTap: () => Get.toNamed('/profile-screen'),
                          leading: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            user?.fullName ?? 'admin_user'.tr,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            user?.email ?? 'admin@krishilink.com',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed:
                                () => PopupService.info(
                                  'edit_profile_tapped'.tr,
                                  title: 'profile'.tr,
                                ),
                          ),
                        );
                      }),
                      const Divider(),
                      TextButton.icon(
                        onPressed: () {
                          Get.find<AuthController>().logout();
                          Get.offAllNamed('/login');
                        },
                        icon: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          'logout'.tr,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bgColor,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: bgColor,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        Material(
          elevation: 6,
          shape: const CircleBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSidebar(BuildContext context) {
    final navItems = [
      {
        'route': '/admin/dashboard',
        'icon': Icons.dashboard,
        'label': 'Dashboard',
      },
      {'route': '/admin/users', 'icon': Icons.person, 'label': 'Users'},
      {
        'route': '/admin/markerplace',
        'icon': Icons.store_mall_directory_rounded,
        'label': 'MarketPlace',
      },
      {'route': '/admin/products', 'icon': Icons.grass, 'label': 'Products'},
      {
        'route': '/admin/orders',
        'icon': Icons.shopping_cart,
        'label': 'Orders',
      },
      {
        'route': '/admin/categories',
        'icon': Icons.category,
        'label': 'Categories',
      },
      {
        'route': '/admin/analytics',
        'icon': Icons.analytics,
        'label': 'Analytics',
      },
      {
        'route': '/admin/notifications',
        'icon': Icons.notifications,
        'label': 'Notifications',
      },
      {'route': '/admin/reports', 'icon': Icons.report, 'label': 'Reports'},
      {
        'route': '/admin/moderation',
        'icon': Icons.verified_user,
        'label': 'Moderation',
      },
      {'route': '/admin/settings', 'icon': Icons.settings, 'label': 'Settings'},
    ];

    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'menu'.tr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(item['route']! as String),
                    icon: Icon(
                      item['icon'] as IconData,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      (item['label']! as String).tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    final navItems = [
      {
        'route': '/admin/dashboard',
        'icon': Icons.dashboard,
        'label': 'Dashboard',
      },
      {'route': '/admin/users', 'icon': Icons.person, 'label': 'Users'},
      {'route': '/admin/products', 'icon': Icons.grass, 'label': 'Products'},
      {
        'route': '/admin/products/reviews',
        'icon': Icons.reviews,
        'label': 'Reviews',
      },
      {
        'route': '/admin/orders',
        'icon': Icons.shopping_cart,
        'label': 'Orders',
      },
      {
        'route': '/admin/categories',
        'icon': Icons.category,
        'label': 'Categories',
      },
      {
        'route': '/admin/analytics',
        'icon': Icons.analytics,
        'label': 'Analytics',
      },
      {
        'route': '/admin/notifications',
        'icon': Icons.notifications,
        'label': 'Notifications',
      },
      {'route': '/admin/reports', 'icon': Icons.report, 'label': 'Reports'},
      {
        'route': '/admin/moderation',
        'icon': Icons.verified_user,
        'label': 'Moderation',
      },
      {'route': '/admin/settings', 'icon': Icons.settings, 'label': 'Settings'},
    ];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'menu'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      return ListTile(
                        leading: Icon(
                          item['icon'] as IconData,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          (item['label']! as String).tr,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          Get.back();
                          Get.toNamed(item['route']! as String);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _SalesData {
  final String day;
  final double sales;

  _SalesData(this.day, this.sales);
}
