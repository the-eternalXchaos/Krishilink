import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests Camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return _handlePermissionStatus(
      Permission.camera,
      status,
      'Camera',
      'Camera permission is required to take photos.',
    );
  }

  /// Requests Storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return _handlePermissionStatus(
      Permission.storage,
      status,
      'Storage',
      'Storage permission is required to access photos and files.',
    );
  }

  /// Handles permission status and shows dialogs as needed
  static Future<bool> _handlePermissionStatus(
    Permission permission,
    PermissionStatus status,
    String permissionName,
    String message,
  ) async {
    switch (status) {
      case PermissionStatus.granted:
        debugPrint('[$permissionName] Permission granted');
        return true;

      case PermissionStatus.denied:
        debugPrint('[$permissionName] Permission denied');
        final retryResult = await _showPermissionDialog(
          'Permission Required',
          message,
          onRetry: () async {
            final newStatus = await permission.request();
            return _handlePermissionStatus(
              permission,
              newStatus,
              permissionName,
              message,
            );
          },
        );
        return retryResult;

      case PermissionStatus.permanentlyDenied:
        debugPrint('[$permissionName] Permission permanently denied');
        await _showPermissionDialog(
          'Permission Required',
          '$message\n\nPlease enable it in app settings.',
          showSettings: true,
        );
        return false;

      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        // Handle other statuses if needed
        debugPrint('[$permissionName] Permission status: $status');
        return false;
    }
  }

  /// Shows permission dialog with Retry/Open Settings options
  static Future<bool> _showPermissionDialog(
    String title,
    String message, {
    Future<bool> Function()? onRetry,
    bool showSettings = false,
  }) async {
    bool result = false;

    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              result = false;
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              if (showSettings) {
                openAppSettings();
                result = false;
              } else {
                if (onRetry != null) {
                  result = await onRetry();
                }
              }
            },
            child: Text(showSettings ? 'Open Settings' : 'Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result;
  }
}

/**bool granted = await PermissionService.requestCameraPermission();
if (granted) {
  // proceed with camera usage
} else {
  // handle permission denied
}
 */
