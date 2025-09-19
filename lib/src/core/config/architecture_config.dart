import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/src/core/networking/api_client.dart';

/// Configuration for the new feature-first architecture
class ArchitectureConfig {
  static bool _isInitialized = false;

  /// Initialize the new architecture components
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize API client
    ApiClient.instance.initialize(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _isInitialized = true;
  }

  /// Check if architecture is initialized
  static bool get isInitialized => _isInitialized;
}

/// Migration helper to gradually move to new architecture
class MigrationHelper {
  /// List of features that have been migrated to new architecture
  static const List<String> migratedFeatures = ['chat', 'cart', 'payment'];

  /// Check if a feature has been migrated
  static bool isFeatureMigrated(String featureName) {
    return migratedFeatures.contains(featureName);
  }

  /// Get migration status for all features
  static Map<String, bool> getMigrationStatus() {
    const allFeatures = [
      'auth',
      'payment',
      'marketplace',
      'chat',
      'farmer',
      'weather',
      'profile',
      'cart',
      'notifications',
    ];

    return {
      for (final feature in allFeatures)
        feature: migratedFeatures.contains(feature),
    };
  }
}
