import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';
import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final AdminUserController controller = Get.find<AdminUserController>();
  final TextEditingController searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    searchController.addListener(() {
      controller.updateSearchQuery(searchController.text);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Manage Users',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            expandedHeight: 160,
            backgroundColor: Colors.green[700],
            elevation: 4,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryCard(
                          'Total Users',
                          controller.totalUsers,
                          Icons.people,
                          Colors.blue[600]!,
                        ),
                        _buildSummaryCard(
                          'Active Users',
                          controller.activeUsers,
                          Icons.check_circle,
                          Colors.green[600]!,
                        ),
                        _buildSummaryCard(
                          'New Today',
                          controller.newUsersToday,
                          Icons.person_add,
                          Colors.orange[600]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppWidgets.card(
                      colorScheme: colorScheme,
                      title: 'Filter Users',
                      icon: Icons.filter_list,
                      iconColor: colorScheme.primary,
                      child: Column(
                        children: [
                          AppWidgets.textField(
                            controller: searchController,
                            label: 'Search by Name, Email, Phone, or Address',
                            icon: Icons.search,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppWidgets.dropdown(
                            value: controller.selectedStatusFilter.value,
                            items: ['All', 'Active', 'Blocked'],
                            onChanged: controller.filterUsersByStatus,
                            label: 'Filter by Status',
                            icon: Icons.person,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppWidgets.card(
                      colorScheme: colorScheme,
                      title: 'User List',
                      icon: Icons.people,
                      iconColor: colorScheme.primary,
                      child: Obx(
                        () =>
                            controller.isLoading.value
                                ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: LottieWidget(
                                      path: LottieAssets.contentLoading,
                                      height: 100,
                                    ),
                                  ),
                                )
                                : RefreshIndicator(
                                  onRefresh:
                                      () async => await controller.fetchUsers(),
                                  child:
                                      controller.filteredUsers.isEmpty
                                          ? SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: Text(
                                                'No users found',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          )
                                          : SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columnSpacing: 16,
                                              columns: [
                                                DataColumn(
                                                  label: Text(
                                                    'ID',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Name',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Email',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Phone',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Status',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Actions',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows:
                                                  controller.filteredUsers
                                                      .map(
                                                        (user) => _buildDataRow(
                                                          user,
                                                          controller,
                                                          colorScheme,
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                          ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    RxInt value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Obx(
                () => Text(
                  value.value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    UserModel user,
    AdminUserController controller,
    ColorScheme colorScheme,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            user.id.substring(0, 8) ?? '-', // Shorten ID for display
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            user.fullName,
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            user.email ?? '-',
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            user.phoneNumber ?? '-',
            style: GoogleFonts.poppins(
              color: colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(
          Text(
            user.isBlocked
                ? 'Blocked'
                : user.isActive
                ? 'Active'
                : 'Inactive',
            style: GoogleFonts.poppins(
              color:
                  user.isBlocked
                      ? Colors.red[700]
                      : user.isActive
                      ? Colors.green[700]
                      : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppWidgets.button(
                text: user.isActive ? 'Deactivate' : 'Activate',
                icon:
                    user.isActive
                        ? Icons.offline_bolt
                        : Icons.online_prediction,
                onPressed: () => controller.toggleUserStatus(user.id),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppWidgets.secondaryButton(
                text: 'Delete',
                onPressed:
                    () => Get.defaultDialog(
                      title: 'Confirm Delete',
                      titleStyle: GoogleFonts.poppins(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      content: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Are you sure you want to delete ${user.fullName}?',
                          style: GoogleFonts.poppins(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      confirm: AppWidgets.button(
                        text: 'Confirm',
                        onPressed: () {
                          controller.deleteUser(user.id);
                          Get.back();
                        },
                        colorScheme: colorScheme,
                      ),
                      cancel: AppWidgets.secondaryButton(
                        text: 'Cancel',
                        onPressed: () => Get.back(),
                        colorScheme: colorScheme,
                      ),
                      backgroundColor: colorScheme.surface,
                      radius: 16,
                    ),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
