import 'package:krishi_link/src/core/networking/base_service.dart';
import 'package:krishi_link/src/core/storage/token_storage.dart';
import 'package:krishi_link/src/core/errors/api_exception.dart';

// DTOs
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final String userId;
  final String role;
  final Map<String, dynamic> user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'confirm_password': confirmPassword,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'role': role,
  };
}

/// Authentication service using the new architecture
class AuthService extends BaseService {
  AuthService({super.apiClient});

  /// Login user
  Future<LoginResponse> login(LoginRequest request) async {
    return executeApiCall(() async {
      final response = await apiClient.post(
        '/auth/login',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw const AuthException(message: 'Invalid response from server');
      }

      final loginResponse = LoginResponse.fromJson(response.data);

      // Store tokens
      await TokenStorage.setToken(loginResponse.token);
      await TokenStorage.setRefreshToken(loginResponse.refreshToken);
      await TokenStorage.setUserId(loginResponse.userId);

      return loginResponse;
    });
  }

  /// Register user
  Future<LoginResponse> register(RegisterRequest request) async {
    return executeApiCall(() async {
      final response = await apiClient.post(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw const AuthException(message: 'Invalid response from server');
      }

      final loginResponse = LoginResponse.fromJson(response.data);

      // Store tokens
      await TokenStorage.setToken(loginResponse.token);
      await TokenStorage.setRefreshToken(loginResponse.refreshToken);
      await TokenStorage.setUserId(loginResponse.userId);

      return loginResponse;
    });
  }

  /// Logout user
  Future<void> logout() async {
    return executeApiCall(() async {
      try {
        // Try to logout from server
        await apiClient.post('/auth/logout');
      } catch (e) {
        // Even if server logout fails, clear local tokens
      } finally {
        await TokenStorage.clearAll();
      }
    });
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return TokenStorage.isAuthenticated();
  }

  /// Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    return executeApiCall(() async {
      final response = await apiClient.get('/auth/me');

      if (response.data == null) {
        throw const AuthException(message: 'Failed to get user information');
      }

      return response.data as Map<String, dynamic>;
    });
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    return executeApiCall(() async {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) {
        throw const AuthException(message: 'No refresh token available');
      }

      final response = await apiClient.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.data == null) {
        throw const AuthException(message: 'Failed to refresh token');
      }

      final newToken = response.data['token'] as String;
      await TokenStorage.setToken(newToken);
    });
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    return executeApiCall(() async {
      await apiClient.post('/auth/reset-password', data: {'email': email});
    });
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return executeApiCall(() async {
      await apiClient.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    });
  }
}
