// lib/features/admin/screens/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/admin/controllers/admin_user_controller.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/services/popup_service.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminUserController controller = Get.find<AdminUserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? Center(child: LottieWidget(path: LottieAssets.contentLoading))
                : RefreshIndicator(
                  onRefresh: () async => await controller.fetchUsers(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows:
                            controller.users
                                .map((user) => _buildDataRow(user, controller))
                                .toList(),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  DataRow _buildDataRow(UserModel user, AdminUserController controller) {
    return DataRow(
      cells: [
        DataCell(Text(user.uid.toString())),
        DataCell(Text(user.fullName)),
        DataCell(Text(user.email ?? '-')),
        DataCell(Text(user.role.capitalizeFirst ?? user.role)),
        DataCell(Text(user.isActive ? 'Online' : 'Offline')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(
                  user.isActive ? Icons.offline_bolt : Icons.online_prediction,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                onPressed:
                    () => controller.toggleUserStatus(user.uid.toString()),
                tooltip: user.isActive ? 'Set Offline' : 'Set Online',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () => Get.defaultDialog(
                      title: 'Confirm Delete',
                      middleText: 'Delete user ${user.fullName}?',
                      onConfirm: () {
                        controller.deleteUser(user.uid.toString());
                        Get.back();
                      },
                      onCancel: () => Get.back(),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
