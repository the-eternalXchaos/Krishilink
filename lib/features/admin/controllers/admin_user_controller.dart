// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/models/user_model.dart';

// class AdminUserController extends GetxController {
//   final RxList<UserModel> users = <UserModel>[].obs;
//   final RxInt totalUsers = 0.obs;
//   final RxInt newUsersToday = 0.obs;
//   final RxInt activeFarmers = 0.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchUsers();
//   }

//   void fetchUsers() {
//     // Mock data
//     final mockUsers = [
//       UserModel(
//         uid: '1',
//         fullName: 'Ram Bahadur',
//         email: 'ram@krishilink.com',
//         phoneNumber: '9801234567',
//         role: 'farmer',
//         createdAt: DateTime.now().subtract(const Duration(days: 30)),
//       ),
//       UserModel(
//         uid: '2',
//         fullName: 'Sita Kumari',
//         email: 'sita@krishilink.com',
//         phoneNumber: '9812345678',
//         role: 'buyer',
//         createdAt: DateTime.now().subtract(const Duration(days: 1)),
//       ),
//       UserModel(
//         uid: '3',
//         fullName: 'Hari Prasad',
//         email: 'hari@krishilink.com',
//         phoneNumber: '9823456789',
//         role: 'farmer',
//         createdAt: DateTime.now(),
//       ),
//     ];
//     users.assignAll(mockUsers);
//     totalUsers.value = mockUsers.length;
//     newUsersToday.value =
//         mockUsers
//             .where(
//               (user) =>
//                   user.createdAt?.day == DateTime.now().day &&
//                   user.createdAt?.month == DateTime.now().month &&
//                   user.createdAt?.year == DateTime.now().year,
//             )
//             .length;
//     activeFarmers.value =
//         mockUsers.where((user) => user.role == 'farmer').length;
//   }
// }

// lib/features/admin/controller/admin_user_controller.dart
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/features/admin/models/user_model.dart';
import 'package:krishi_link/services/token_service.dart';

class AdminUserController extends GetxController {
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final totalUsers = 0.obs;
  final activeFarmers = 0.obs;
  final newUsersToday = 0.obs;

  final dio.Dio _dio = dio.Dio(
    dio.BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  @override
  void onInit() {
    super.onInit();

    Future.delayed(const Duration(milliseconds: 50), () => fetchUsers());
    // fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading(true);
      final token = await TokenService.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.getUserDetailsEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        users.assignAll(data.map((json) => UserModel.fromJson(json)).toList());
        totalUsers.value = users.length;
        activeFarmers.value =
            users
                .where((u) => u.role.toLowerCase() == 'farmer' && u.isActive)
                .length;
        newUsersToday.value =
            users.where((u) {
              return u.createdAt != null &&
                  u.createdAt!.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  );
            }).length;
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      PopupService.error('Failed to load users: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>> fetchFarmerDetails(String phone) async {
    try {
      final token = await TokenService.getAccessToken();
      if (token == null) throw Exception('No authentication token');
      final response = await _dio.get(
        '${ApiConstants.getUserDetailsByPhoneNumber}/$phone',
        options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return {
          'farmerId': response.data['farmerId']?.toString() ?? '',
          'farmerName': response.data['fullName']?.toString() ?? '',
        };
      } else {
        return {};
      }
    } catch (e) {
      PopupService.error('Failed to fetch farmer: $e');
      return {};
    }
  }

  Future<void> toggleUserStatus(String uid) async {
    try {
      isLoading(true);
      final user = users.firstWhere((u) => u.uid == uid);
      final response = await http.put(
        Uri.parse('${ApiConstants.updateProfileEndpoint}?uid=$uid'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'isActive': !user.isActive}),
      );

      if (response.statusCode == 200) {
        users[users.indexOf(user)] = user.copyWith(isActive: !user.isActive);
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

  Future<void> deleteUser(String uid) async {
    try {
      isLoading(true);
      // Hypothetical endpoint; replace with actual if available
      final response = await http.delete(
        Uri.parse('${ApiConstants.deleteUserEndpoint}/$uid'),
        headers: {
          'Authorization': 'Bearer ${await TokenService.getAccessToken()}',
        },
      );

      if (response.statusCode == 200) {
        users.removeWhere((u) => u.uid == uid);
        totalUsers.value = users.length;
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
}
