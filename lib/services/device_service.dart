// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class DeviceService {
//   final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
//   static const _cacheKey = 'cached_device_id';

//   /// Returns a stable device ID (real if available, otherwise generated UUID).
//   Future<String> getDeviceId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();

//       // If cached, return that
//       final cached = prefs.getString(_cacheKey);
//       if (cached != null && cached.isNotEmpty) {
//         debugPrint('[DeviceService] Returning cached ID: $cached');
//         return cached;
//       }

//       String? deviceId;

//       if (Platform.isAndroid) {
//         final androidInfo = await _deviceInfo.androidInfo;
//         // `id` = build ID (not unique, changes with OS updates)
//         final buildId = androidInfo.id;
//         debugPrint('[DeviceService] androidInfo.id (build ID): $buildId');

//         // Use buildId if available (not guaranteed unique)
//         if (buildId.isNotEmpty) {
//           deviceId = 'android_$buildId';
//         }
//       } else if (Platform.isIOS) {
//         final iosInfo = await _deviceInfo.iosInfo;
//         final identifier = iosInfo.identifierForVendor; // Stable per install
//         debugPrint('[DeviceService] iosInfo.identifierForVendor: $identifier');
//         deviceId = identifier;
//       } else {
//         debugPrint('[DeviceService] Unsupported platform');
//         deviceId = 'unsupported_platform';
//       }

//       // Fallback: Generate a UUID and store it
//       deviceId ??= const Uuid().v4();

//       await prefs.setString(_cacheKey, deviceId);
//       debugPrint('[DeviceService] Returning (new) ID: $deviceId');
//       return deviceId;
//     } catch (e) {
//       debugPrint('[DeviceService] Error fetching deviceId: $e');
//       return 'error_${e.toString()}';
//     }
//   }
// }
