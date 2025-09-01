import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/services/token_service.dart';

class AdminUserController extends GetxController {
  final users = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final isLoading = false.obs;
  final totalUsers = 0.obs;
  final activeUsers = 0.obs; // Changed from activeFarmers
  final newUsersToday = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatusFilter =
      'All'.obs; // Changed to filter by isActive/isBlocked

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedStatusFilter, (_) => _applyFilters());
  }

  Future<void> fetchUsers() async {
    try {
      isLoading(true);
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.getUserDetailsByIdEndpoint),

        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        users.assignAll(data.map((json) => UserModel.fromJson(json)).toList());
        totalUsers.value = users.length;
        activeUsers.value = users.where((u) => u.isActive).length;
        newUsersToday.value =
            users.where((u) {
              return u.createdAt != null &&
                  u.createdAt!.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );
            }).length;
        _applyFilters();
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to load users: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleUserStatus(String id) async {
    try {
      isLoading(true);
      final user = users.firstWhere((u) => u.id == id);
      final response = await http.put(
        Uri.parse('${ApiConstants.updateProfileEndpoint}?id=$id'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': !user.isActive}),
      );

      if (response.statusCode == 200) {
        users[users.indexOf(user)] = user.copyWith(isActive: !user.isActive);
        _applyFilters();
        PopupService.info(
          'User ${user.isActive ? 'deactivated' : 'activated'}',
        );
      } else {
        throw Exception('Failed to update user status');
      }
    } catch (e) {
      PopupService.showSnackbar(
        title: 'Error',
        message: 'Failed to update user status: $e',
        type: PopupType.error,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      isLoading(true);
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteUserEndpoint}/$id'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
        },
      );

      if (response.statusCode == 200) {
        users.removeWhere((u) => u.id == id);
        totalUsers.value = users.length;
        _applyFilters();
        PopupService.showSnackbar(
          type: PopupType.success,
          title: 'Success',
          message: 'User deleted',
        );
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.showSnackbar(
        type: PopupType.error,
        title: 'Error',
        message: 'Failed to delete user: $e',
      );
    } finally {
      isLoading(false);
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void filterUsersByStatus(String? status) {
    selectedStatusFilter.value = status ?? 'All';
  }

  void _applyFilters() {
    var result = users.toList();
    if (searchQuery.value.isNotEmpty) {
      final lowerQuery = searchQuery.value.toLowerCase();
      result =
          result.where((user) {
            return user.fullName.toLowerCase().contains(lowerQuery) ||
                (user.email?.toLowerCase().contains(lowerQuery) ?? false) ||
                (user.phoneNumber?.toLowerCase().contains(lowerQuery) ??
                    false) ||
                (user.address?.toLowerCase().contains(lowerQuery) ?? false) ||
                (user.city?.toLowerCase().contains(lowerQuery) ?? false);
          }).toList();
    }
    if (selectedStatusFilter.value != 'All') {
      if (selectedStatusFilter.value == 'Active') {
        result = result.where((user) => user.isActive).toList();
      } else if (selectedStatusFilter.value == 'Blocked') {
        result = result.where((user) => user.isBlocked).toList();
      }
    }
    filteredUsers.assignAll(result);
  }
}
