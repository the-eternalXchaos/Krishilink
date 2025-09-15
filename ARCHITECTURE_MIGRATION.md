# Feature-First Architecture Migration Guide

## Overview

This project is being restructured from a traditional Flutter folder structure to a **feature-first architecture** to improve:

- ✅ **Scalability** - Each feature is self-contained and independently testable
- ✅ **Maintainability** - Clear separation of concerns and dependencies
- ✅ **Team Collaboration** - Different teams can work on different features
- ✅ **Code Reusability** - Shared core components and utilities

## New Architecture Structure

```
lib/
├── src/                              # New feature-first architecture
│   ├── core/                         # Cross-cutting concerns
│   │   ├── networking/               # HTTP client, base services
│   │   ├── storage/                  # Token management, local storage
│   │   ├── errors/                   # Exception handling
│   │   ├── utils/                    # Shared utilities
│   │   ├── design_system/            # UI components, themes
│   │   └── assets/                   # Images, fonts, etc.
│   └── features/                     # Feature modules
│       ├── auth/
│       │   ├── data/                 # API services, DTOs, cache
│       │   └── presentation/         # Controllers, screens, widgets
│       ├── payment/
│       │   ├── data/
│       │   └── presentation/
│       ├── marketplace/
│       │   ├── data/
│       │   └── presentation/
│       └── ...
├── core/                             # Legacy core (being phased out)
├── features/                         # Legacy features (being migrated)
├── services/                         # Legacy services (now shims)
└── widgets/                          # Legacy widgets (being moved to features)
```

## Migration Strategy

### Phase 1: Infrastructure Setup ✅
- [x] Create new `/src` directory structure
- [x] Set up core networking layer (`ApiClient`, `BaseService`)
- [x] Implement token storage and error handling
- [x] Create architecture configuration

### Phase 2: Feature Migration (In Progress)
- [x] **Payment** - Moved to `src/features/payment/data/`
- [x] **Auth** - Moved to `src/features/auth/data/`
- [x] **Marketplace** - Moved to `src/features/marketplace/data/`
- [ ] **Chat** - To be migrated
- [ ] **Farmer** - To be migrated
- [ ] **Weather** - To be migrated
- [ ] **Profile** - To be migrated

### Phase 3: Cleanup
- [ ] Remove legacy shim files
- [ ] Update all imports to use new paths
- [ ] Remove unused legacy code

## How to Use the New Architecture

### 1. Initialize Architecture (Already Done)
```dart
// In main.dart
await ArchitectureConfig.initialize();
```

### 2. Use New Services
```dart
// Old way (still works via shims)
import 'package:krishi_link/services/payment_service.dart';

// New way (preferred)
import 'package:krishi_link/src/features/payment/data/payment_service.dart';

// Usage
final paymentService = PaymentService();
final result = await paymentService.initiatePayment(/* ... */);
```

### 3. Error Handling
```dart
try {
  final result = await someService.doSomething();
} on ApiException catch (e) {
  // Handle API errors
  print('Error: ${e.message}');
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

## Core Components

### ApiClient
Centralized HTTP client with:
- Automatic token injection
- Request/response logging
- Error handling
- Timeout configuration

### BaseService
Base class for all API services providing:
- Common error handling
- Consistent API patterns
- Error message formatting

### TokenStorage
Secure token management:
- Get/Set authentication tokens
- Automatic token clearing on 401 errors
- User session management

## Migration Checklist for New Features

When migrating a feature to the new architecture:

### 1. Create Feature Structure
```bash
src/features/your_feature/
├── data/
│   ├── your_feature_service.dart
│   ├── dtos/
│   └── cache/
└── presentation/
    ├── controllers/
    ├── screens/
    └── widgets/
```

### 2. Move API Logic
- [ ] Create service class extending `BaseService`
- [ ] Define request/response DTOs
- [ ] Use `executeApiCall()` for error handling

### 3. Create Shim File
```dart
// services/legacy_service.dart
export 'package:krishi_link/src/features/your_feature/data/your_feature_service.dart';
```

### 4. Update Tests
- [ ] Test new service independently
- [ ] Mock `ApiClient` for unit tests
- [ ] Integration tests for API endpoints

## Benefits of New Architecture

### Before (Legacy)
```dart
// Scattered service files
services/
├── auth_services.dart
├── farmer_api_service.dart
├── payment_service.dart
└── ml_service.dart

// Controllers mixed with business logic
controllers/
├── auth_controller.dart      # Auth + UI logic
├── product_controller.dart   # Products + UI logic
└── ...
```

### After (New)
```dart
// Feature-based organization
src/features/auth/
├── data/auth_service.dart           # Pure API logic
└── presentation/auth_controller.dart # Pure UI logic

src/features/marketplace/
├── data/marketplace_service.dart
└── presentation/product_controller.dart
```

## Development Guidelines

### 1. Data Layer (Pure Business Logic)
- No Flutter/UI dependencies
- Only data transformation and API calls
- Testable without UI framework

### 2. Presentation Layer (UI Logic)
- Controllers, screens, widgets
- Uses data layer services
- Handles UI state management

### 3. Core Layer (Shared Utilities)
- No feature-specific logic
- Reusable across all features
- Infrastructure concerns only

## Next Steps

1. **Continue Feature Migration**: Move remaining features to new structure
2. **Update Import Paths**: Gradually update imports to use new paths
3. **Remove Legacy Code**: Once migration is complete, remove shim files
4. **Add Tests**: Write comprehensive tests for new services
5. **Documentation**: Update API documentation and team guidelines

## Questions or Issues?

If you encounter any issues during migration:
1. Check if the feature has been migrated (`MigrationHelper.isFeatureMigrated()`)
2. Use shim imports while migration is ongoing
3. Follow the established patterns in already-migrated features

---

**Status**: 🟡 In Progress - Core infrastructure complete, feature migration ongoing
