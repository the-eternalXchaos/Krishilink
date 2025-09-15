import 'dart:async';

/// Simple connectivity service placeholder to satisfy imports during migration.
class ConnectivityService {
  static final ConnectivityService I = ConnectivityService._internal();
  ConnectivityService._internal();
  ConnectivityService(); // public default ctor for Get.put

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  void dispose() => _controller.close();
}
