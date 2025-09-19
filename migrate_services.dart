// #!/usr/bin/env dart
// // Service Migration Automation Script
// // This script helps migrate service files to the new feature-first architecture

// import 'dart:io';
// import 'dart:convert';

// class ServiceMigrator {
//   final Map<String, String> migrationMap = {
//     // Authentication Services
//     'services/auth_services.dart': 'src/features/auth/data/auth_service.dart',
//     'services/auth_services_new.dart':
//         'src/features/auth/data/auth_service_new.dart',
//     'services/token_service.dart': 'src/features/auth/data/token_service.dart',

//     // Chat Services
//     'features/chat/services/chat_api_service.dart':
//         'src/features/chat/data/chat_api_service.dart',
//     'features/chat/services/chat_realtime_service.dart':
//         'src/features/chat/data/chat_realtime_service.dart',
//     'features/chat/services/signalr_service.dart':
//         'src/features/chat/data/signalr_service.dart',
//     'features/chat/services/product_chat_api_service.dart':
//         'src/features/chat/data/product_chat_api_service.dart',
//     'features/chat/services/chat_notification_service.dart':
//         'src/features/chat/data/chat_notification_service.dart',
//     'features/chat/services/chat_cache_service.dart':
//         'src/features/chat/data/chat_cache_service.dart',
//     'features/chat/services/background_message_handler.dart':
//         'src/features/chat/data/background_message_handler.dart',

//     // Farmer Services
//     'services/farmer_api_service.dart':
//         'src/features/farmer/data/farmer_api_service.dart',

//     // Weather Services
//     'features/weather/weather_api_services.dart':
//         'src/features/weather/data/weather_api_service.dart',

//     // Notification Services
//     'features/notification/services/notification_apiservice.dart':
//         'src/features/notification/data/notification_api_service.dart',

//     // AI/ML Services
//     'features/ai_chat/ai_api_service.dart':
//         'src/features/ai_chat/data/ai_api_service.dart',
//     'services/ml_service.dart': 'src/features/ai_chat/data/ml_service.dart',

//     // Core Utility Services
//     'services/device_service.dart': 'src/core/services/device_service.dart',
//     'services/permission_service.dart':
//         'src/core/services/permission_service.dart',
//     'services/popup_service.dart': 'src/core/services/popup_service.dart',
//     'services/role_service.dart': 'src/core/services/role_service.dart',

//     // API Services
//     'services/api_service_new.dart': 'src/core/networking/api_service_new.dart',
//     'services/api_services/api_service.dart':
//         'src/core/networking/legacy_api_service.dart',
//   };

//   void migrateServices() {
//     print('🚀 Starting service migration to feature-first architecture...\n');

//     for (final entry in migrationMap.entries) {
//       migrateService(entry.key, entry.value);
//     }

//     print('\n✅ Migration completed!');
//     print('\n📝 Next steps:');
//     print('1. Review all migrated files');
//     print('2. Update imports gradually');
//     print('3. Remove shim files after migration is complete');
//     print('4. Run flutter analyze to check for issues');
//   }

//   void migrateService(String oldPath, String newPath) {
//     final oldFile = File('lib/$oldPath');
//     final newFile = File('lib/$newPath');

//     if (!oldFile.existsSync()) {
//       print('⚠️  Skipping $oldPath (file not found)');
//       return;
//     }

//     if (newFile.existsSync()) {
//       print('ℹ️  Skipping $oldPath (already migrated)');
//       return;
//     }

//     print('📦 Migrating: $oldPath → $newPath');

//     // Create directories if they don't exist
//     newFile.parent.createSync(recursive: true);

//     // Read original file content
//     final content = oldFile.readAsStringSync();

//     // Update imports in the content
//     final updatedContent = updateImports(content);

//     // Write to new location
//     newFile.writeAsStringSync(updatedContent);

//     // Create export shim in old location
//     createExportShim(oldFile, newPath);

//     print('✅ Migrated: $oldPath');
//   }

//   String updateImports(String content) {
//     // Common import patterns to update
//     final importUpdates = {
//       // Update relative imports to new architecture
//       "import '../": "import 'package:krishi_link/src/",
//       "import '../../": "import 'package:krishi_link/src/",
//       "import '../../../": "import 'package:krishi_link/src/",
//       "import '../../../../": "import 'package:krishi_link/src/",

//       // Update common service imports
//       "import 'package:krishi_link/services/":
//           "import 'package:krishi_link/src/features/",
//       "import 'package:krishi_link/features/":
//           "import 'package:krishi_link/src/features/",

//       // Update core imports
//       "import 'package:krishi_link/core/":
//           "import 'package:krishi_link/src/core/",
//     };

//     String updatedContent = content;

//     for (final update in importUpdates.entries) {
//       updatedContent = updatedContent.replaceAll(update.key, update.value);
//     }

//     return updatedContent;
//   }

//   void createExportShim(File oldFile, String newPath) {
//     final shimContent = '''// Export shim for backward compatibility
// // This service has been moved to the new architecture
// export 'package:krishi_link/lib/$newPath';''';

//     oldFile.writeAsStringSync(shimContent);
//   }
// }

// void main() {
//   final migrator = ServiceMigrator();
//   migrator.migrateServices();
// }
