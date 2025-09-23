import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  // Singleton instance
  static final ConnectivityService I = ConnectivityService._internal();
  ConnectivityService._internal();
  ConnectivityService(); // public default ctor for Get.put

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  final RxBool isOffline = false.obs;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  void _startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasInternet = await _hasInternetAccess();
      final offline = !hasInternet;

      // Emit changes only when state changes
      if (offline != isOffline.value) {
        isOffline.value = offline;
        _controller.add(offline); // legacy stream support
      }
    });

    // Initial check
    _initialCheck();
  }

  Future<void> _initialCheck() async {
    final hasInternet = await _hasInternetAccess();
    isOffline.value = !hasInternet;
    _controller.add(!hasInternet);
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    _controller.close();
    super.onClose();
  }
}
