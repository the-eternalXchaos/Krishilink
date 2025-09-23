// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:get/get.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:krishi_link/core/utils/api_constants.dart';
// import 'package:krishi_link/exceptions/app_exception.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:krishi_link/features/admin/models/user_model.dart';
// import 'package:dio/dio.dart' as dio;

// class TokenService {
//   // Tracks whether the last refresh attempt failed due to a network error.
//   static bool lastRefreshWasNetworkError = false;
//   static const _storage = FlutterSecureStorage();
//   static const _tokenKey = 'access_token';
//   static const _refreshTokenKey = 'refresh_token';
//   static const _expirationKey = 'token_expiration';
//   static const _userKey = 'user_model';

//   static Future<void> saveTokens({
//     required String accessToken,
//     required String refreshToken,
//     required String expiration,
//   }) async {
//     try {
//       debugPrint(
//         '[TokenService] Saving tokens: access=$accessToken, refresh=$refreshToken, exp=$expiration',
//       );
//       // Normalize expiration before persisting so later parsing is reliable.
//       final normalizedExpiration = _normalizeExpiration(expiration);
//       await _storage.write(key: _tokenKey, value: accessToken);
//       await _storage.write(key: _refreshTokenKey, value: refreshToken);
//       await _storage.write(key: _expirationKey, value: normalizedExpiration);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('hasTokens', true);
//       debugPrint('[TokenService] Tokens saved successfully');
//     } catch (e) {
//       debugPrint('[TokenService] Failed to save tokens: $e');
//       throw AppException('Failed to save tokens: $e');
//     }
//   }

//   static Future<void> saveUser(UserModel user) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userJson = jsonEncode(user.toJson());
//       await prefs.setString(_userKey, userJson);
//       debugPrint('[TokenService] User saved: ${user.fullName}');
//     } catch (e) {
//       debugPrint('[TokenService] Failed to save user: $e');
//       throw AppException('Failed to save user: $e');
//     }
//   }

//   static Future<UserModel?> getUser() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userJson = prefs.getString(_userKey);
//       if (userJson == null) {
//         debugPrint('[TokenService] No user found');
//         return null;
//       }
//       final user = UserModel.fromJson(jsonDecode(userJson));
//       debugPrint('[TokenService] User loaded: ${user.fullName}');
//       return user;
//     } catch (e) {
//       debugPrint('[TokenService] Failed to load user: $e');
//       return null;
//     }
//   }

//   static Future<void> clearTokens() async {
//     try {
//       await _storage.delete(key: _tokenKey);
//       await _storage.delete(key: _refreshTokenKey);
//       await _storage.delete(key: _expirationKey);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('hasTokens');
//       await prefs.remove(_userKey);
//       debugPrint('[TokenService] Tokens and user cleared');
//     } catch (e) {
//       debugPrint('[TokenService] Failed to clear tokens: $e');
//       throw AppException('Failed to clear tokens: $e');
//     }
//   }

//   static Future<bool> hasTokens() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final hasTokensFlag = prefs.getBool('hasTokens') ?? false;
//       if (!hasTokensFlag) {
//         debugPrint('[TokenService] No hasTokens flag');
//         return false;
//       }

//       final access = await getAccessToken();
//       final refresh = await getRefreshToken();
//       final expiration = await _storage.read(key: _expirationKey);
//       final result = access != null && refresh != null && expiration != null;
//       debugPrint(
//         '[TokenService] hasTokens: $result (access: ${access != null}, refresh: ${refresh != null}, exp: ${expiration != null})',
//       );
//       return result;
//     } catch (e) {
//       debugPrint('[TokenService] hasTokens error: $e');
//       return false;
//     }
//   }

//   static Future<String?> getAccessToken() async {
//     try {
//       final token = await _storage.read(key: _tokenKey);
//       if (token?.isNotEmpty == true) {
//         debugPrint('[TokenService] Access token retrieved');
//         return token;
//       }
//       debugPrint('[TokenService] No access token found');
//       return null;
//     } catch (e) {
//       debugPrint('[TokenService] Error reading access token: $e');
//       return null;
//     }
//   }

//   static Future<String?> getRefreshToken() async {
//     try {
//       final token = await _storage.read(key: _refreshTokenKey);
//       if (token?.isNotEmpty == true) {
//         debugPrint('[TokenService] Refresh token retrieved');
//         return token;
//       }
//       debugPrint('[TokenService] No refresh token found');
//       return null;
//     } catch (e) {
//       debugPrint('[TokenService] Error reading refresh token: $e');
//       return null;
//     }
//   }

//   static Future<bool> isTokenExpired() async {
//     try {
//       final token = await getAccessToken();
//       if (token == null) {
//         debugPrint('[TokenService] No token to check expiration');
//         return true;
//       }

//       if (JwtDecoder.isExpired(token)) {
//         debugPrint('[TokenService] Token expired (JWT)');
//         return true;
//       }

//       final expStr = await _storage.read(key: _expirationKey);
//       if (expStr == null) {
//         debugPrint('[TokenService] No expiration stored');
//         return true;
//       }
//       final expiryDate = _parseExpiration(expStr);
//       final isExpired = DateTime.now().isAfter(expiryDate);
//       debugPrint(
//         '[TokenService] Token expiration check: isExpired=$isExpired, expiry=$expStr',
//       );
//       return isExpired;
//     } catch (e) {
//       debugPrint('[TokenService] Error checking token expiration: $e');
//       return true;
//     }
//   }

//   static Future<bool> refreshAccessToken() async {
//     try {
//       debugPrint('[TokenService] --- refreshAccessToken called ---');
//       final refreshToken = await getRefreshToken();
//       debugPrint('[TokenService] Using refresh token: $refreshToken');
//       if (refreshToken == null) {
//         debugPrint('[TokenService] No refresh token available');
//         return false;
//       }

//       final dioClient = dio.Dio();
//       // Use multipart/form-data as required by backend
//       final formData = dio.FormData.fromMap({'refreshToken': refreshToken});
//       final response = await dioClient.post(
//         ApiConstants.refreshTokenEndpoint,
//         data: formData,
//         options: dio.Options(
//           contentType: 'multipart/form-data',
//           validateStatus: (status) => status != null && status < 500,
//         ),
//       );
//       debugPrint('[TokenService] Refresh response data: ${response.data}');
//       //TODO if the response is offline type or the use is offline dont push the user to the login page
//       if (response.statusCode == 404) {
//         debugPrint(
//           '[TokenService] Token refresh failed: ${response.statusCode} (unauthorized or not found)',
//         );
//         await clearTokens();
//         debugPrint('[TokenService] Tokens cleared due to 404');
//         return false;
//       }
//       if (response.statusCode != 200) {
//         debugPrint(
//           '[TokenService] Token refresh failed: ${response.statusCode}',
//         );
//         // For other errors, do NOT clear tokens, just return false
//         return false;
//       }

//       final data = response.data is Map<String, dynamic> ? response.data : {};
//       final apiData = data['data'] ?? {};
//       debugPrint('[TokenService] Parsed API data: $apiData');
//       await saveTokens(
//         accessToken: apiData['token'] ?? '',
//         refreshToken: apiData['refreshToken'] ?? '',
//         expiration: apiData['expiration'] ?? DateTime.now().toIso8601String(),
//       );
//       debugPrint('[TokenService] Token refreshed successfully');
//       return true;
//     } on dio.DioException catch (e) {
//       debugPrint('[TokenService] --- DioException in refreshAccessToken ---');
//       debugPrint('[TokenService] DioException details: $e');
//       debugPrint('[TokenService] DioException type: ${e.type}');
//       debugPrint('[TokenService] DioException response: ${e.response}');
//       if (_isNetworkError(e)) {
//         debugPrint(
//           '[TokenService] Network error during refresh, keeping tokens',
//         );
//         return false;
//       }
//       if (_isUnauthorizedOrNotFoundError(e)) {
//         debugPrint(
//           '[TokenService] Unauthorized/NotFound Dio error, clearing tokens',
//         );
//         await clearTokens();
//         return false;
//       }
//       debugPrint(
//         '[TokenService] Other Dio error during refresh, keeping tokens',
//       );
//       return false;
//     } catch (e) {
//       debugPrint('[TokenService] --- Exception in refreshAccessToken ---');
//       debugPrint('[TokenService] Exception details: $e');
//       // For all other errors, do NOT clear tokens
//       return false;
//     }
//   }

//   static bool _isNetworkError(dio.DioException e) {
//     return e.type == dio.DioExceptionType.connectionError ||
//         e.type == dio.DioExceptionType.unknown ||
//         e.error is Exception;
//   }

//   static bool _isUnauthorizedOrNotFoundError(dio.DioException e) {
//     final code = e.response?.statusCode;
//     return code == 404;
//   }

//   static Future<Map<String, String>> getAuthHeaders() async {
//     try {
//       var token = await getAccessToken();
//       if (token == null || await isTokenExpired()) {
//         final refreshed = await refreshAccessToken();
//         if (!refreshed) {
//           await clearTokens();
//           Get.offAllNamed('/login');
//           throw AppException('Authentication required');
//         }
//         token = await getAccessToken();
//       }

//       if (token == null) {
//         throw AppException('No valid token available');
//       }

//       final headers = {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//         'Accept': '*/*',
//       };
//       debugPrint('[TokenService] Auth headers: $headers');
//       return headers;
//     } catch (e) {
//       debugPrint('[TokenService] Error getting auth headers: $e');
//       throw AppException('Failed to build auth headers');
//     }
//   }

//   static Future<Map<String, dynamic>?> getDecodedTokenPayload() async {
//     try {
//       final token = await getAccessToken();
//       if (token == null) {
//         debugPrint('[TokenService] No token to decode');
//         return null;
//       }
//       final payload = JwtDecoder.decode(token);
//       debugPrint('[TokenService] Decoded payload: $payload');
//       return payload;
//     } catch (e) {
//       debugPrint('[TokenService] Error decoding token: $e');
//       return null;
//     }
//   }

//   // --- Private helpers --------------------------------------------------

//   // Accepts several possible backend formats and returns a DateTime.
//   // Supported examples:
//   // 1) ISO 8601: 2025-09-17T10:03:13.000Z
//   // 2) Backend AM/PM: 2025-09-17 10:03:13 AM
//   // 3) Backend 24h  : 2025-09-17 14:03:13
//   static DateTime _parseExpiration(String raw) {
//     // Fast path: try native parse (handles ISO 8601 & "yyyy-MM-dd HH:mm:ss")
//     try {
//       final dt = DateTime.parse(raw);
//       return dt; // Already has timezone info or treated as local.
//     } catch (_) {
//       // fall through
//     }

//     // Try AM/PM format.
//     final patterns = <String>[
//       'yyyy-MM-dd hh:mm:ss a', // 12h with AM/PM
//       'yyyy-MM-dd HH:mm:ss', // 24h without AM/PM
//     ];
//     for (final p in patterns) {
//       try {
//         final fmt = DateFormat(p);
//         return fmt.parse(raw, false); // treat as local time
//       } catch (_) {
//         // continue
//       }
//     }

//     // As last resort, return now so caller treats as expired soon.
//     debugPrint(
//       '[TokenService] Unknown expiration format: "$raw"; defaulting to now',
//     );
//     return DateTime.now();
//   }

//   // Normalize any backend expiration string to ISO8601 (UTC) for consistent future parsing.
//   static String _normalizeExpiration(String raw) {
//     final dt = _parseExpiration(raw);
//     // Store in UTC to avoid device timezone skew; some server strings are local w/out TZ.
//     return dt.toUtc().toIso8601String();
//   }
// }
