import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a unique device ID depending on the platform
  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id.isNotEmpty
            ? androidInfo.id
            : androidInfo.androidId ?? 'unknown_device';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_device';
      } else {
        return 'unsupported_platform';
      }
    } catch (e) {
      // Log or handle the error properly in production
      return 'error_${e.toString()}';
    }
  }
}

extension on AndroidDeviceInfo {
  get androidId => null;
}
