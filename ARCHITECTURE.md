# Application Architecture

## Core Layout
- `lib/src/` — **Feature-first (canonical)**
  - `src/features/<feature>/data` → API services, DTOs, cache (extend `BaseService`)
  - `src/features/<feature>/presentation` → controllers, screens, widgets
  - `src/core/networking` → `ApiClient`, `BaseService` (shared Dio, token interceptor)
  - `src/core/*` → errors, storage, design system, utils
- `lib/features/` — **Legacy feature tree (export shims)**
  - Legacy controllers/screens/services that now *export* files from `src/`
- `lib/services/` — **Legacy global services (export shims)**
- `lib/core/` — Legacy shared (assets, theme, routes, constants)

## File Structure
```
lib/
├─ src/                           # New canonical architecture
│  ├─ core/
│  │  ├─ networking/
│  │  │  ├─ api_client.dart       # Shared Dio client with interceptors
│  │  │  └─ base_service.dart     # Base class for all services
│  │  ├─ errors/
│  │  │  └─ api_exception.dart    # Centralized error handling
│  │  ├─ storage/
│  │  │  └─ token_storage.dart    # Secure token management
│  │  └─ models/
│  │     └─ cart_item.dart        # Shared models
│  └─ features/
│     ├─ auth/
│     │  └─ data/
│     │     └─ auth_service.dart          # Authentication API
│     ├─ payment/
│     │  └─ data/
│     │     └─ payment_service.dart       # Khalti payment integration
│     ├─ marketplace/
│     │  └─ data/
│     │     └─ marketplace_service.dart   # Product CRUD operations
│     ├─ farmer/
│     │  └─ data/
│     │     └─ farmer_api_service.dart    # Farmer-specific APIs
│     ├─ weather/
│     │  └─ data/
│     │     └─ weather_api_service.dart   # Weather data fetching
│     └─ chat/
│        └─ data/
│           └─ chat_service.dart          # Real-time messaging
│
├─ features/                      # Legacy (export shims during migration)
│  ├─ auth/
│  ├─ payment/
│  ├─ farmer/
│  ├─ weather/
│  └─ chat/
│
├─ services/                      # Legacy global services (export shims)
│  ├─ auth_services.dart          → exports src/features/auth/data/
│  ├─ farmer_api_service.dart     → exports src/features/farmer/data/
│  ├─ payment_service.dart        → exports src/features/payment/data/
│  └─ ...
│
└─ core/                          # Legacy shared infrastructure
   ├─ assets/                     # Images, animations, icons
   ├─ components/                 # Reusable UI components
   ├─ constants/                  # App constants and routes
   ├─ theme/                      # App theming
   └─ translations/               # Internationalization
```

## Architecture Highlights

### ✅ **Feature-First Design**
- **Vertical slices**: Each feature owns its data + presentation layers
- **Cross-cutting concerns**: Shared infrastructure in `src/core/`
- **Clear boundaries**: Features are independent and composable

### ✅ **Backward Compatibility**
- **Export shims**: Legacy files export new `src/` paths
- **Zero breaking changes**: Old imports continue working during migration
- **Gradual migration**: Move code piece by piece without disruption

### ✅ **Centralized HTTP Management**
- **ApiClient**: Single Dio instance with token interceptors
- **BaseService**: Common functionality for all services
- **Consistent error handling**: Unified exception management
- **Token management**: Automatic authorization headers

### ✅ **Migration Strategy**
- **Phase 1**: ✅ Core infrastructure (`ApiClient`, `BaseService`, error handling)
- **Phase 2**: ✅ Service migration to `src/features/**/data` 
- **Phase 3**: 🔜 Controller migration to `src/features/**/presentation`
- **Phase 4**: 🔜 Reduce legacy `core/components/*` 

## Migration Status

### ✅ **Completed Services**
- **Authentication**: `src/features/auth/data/auth_service.dart`
- **Payment Processing**: `src/features/payment/data/payment_service.dart`
- **Marketplace/Products**: `src/features/marketplace/data/marketplace_service.dart`
- **Farmer APIs**: `src/features/farmer/data/farmer_api_service.dart`
- **Weather Data**: `src/features/weather/data/weather_api_service.dart`

### ✅ **Export Shims Created**
- `lib/services/auth_services.dart` → `src/features/auth/data/`
- `lib/services/farmer_api_service.dart` → `src/features/farmer/data/`
- `lib/services/payment_service.dart` → `src/features/payment/data/`
- `lib/features/weather/weather_api_services.dart` → `src/features/weather/data/`

### 🔜 **Pending Migrations**
- Chat services → `src/features/chat/data/`
- Notification services → `src/features/notification/data/`
- Controllers → `src/features/**/presentation/controllers/`
- Screens → `src/features/**/presentation/screens/`
- Widgets → `src/features/**/presentation/widgets/`

## Key Features

### 🏗️ **Application Features**
- **Multi-role System**: Admin, Farmer, Buyer dashboards
- **Real-time Chat**: SignalR-powered messaging system
- **Payment Integration**: Khalti payment gateway
- **AI Features**: Disease detection, weather integration
- **Product Management**: CRUD operations for marketplace

### 📱 **Platform Support**
- **Mobile**: Android, iOS (production-ready)
- **Desktop**: Windows, macOS, Linux (cross-platform)
- **Web**: Progressive Web App (PWA) support

### 🔧 **Technical Stack**
- **Framework**: Flutter with GetX state management
- **HTTP**: Dio client with interceptors
- **Storage**: GetStorage + SharedPreferences
- **Real-time**: SignalR for chat functionality
- **Payments**: Khalti integration
- **API**: RESTful backend integration

## Development Guidelines

### 🎯 **New Code Guidelines**
1. **Services**: Always extend `BaseService` and place in `src/features/<feature>/data/`
2. **Controllers**: Place in `src/features/<feature>/presentation/controllers/`
3. **Screens**: Place in `src/features/<feature>/presentation/screens/`
4. **Models**: Feature-specific models in feature folders, shared models in `src/core/models/`

### ⚠️ **Legacy Code Policy**
1. **No new code** in `lib/features/` (except export shims)
2. **No new code** in `lib/services/` (except export shims)
3. **Gradual migration** of existing controllers/screens to `src/` structure

### 🔒 **Import Guidelines**
- **Prefer**: Direct imports from `src/features/**/data/`
- **Transitional**: Legacy imports via export shims (during migration)
- **Avoid**: Cross-feature dependencies (use events or shared services)

## Architecture Benefits

### ✅ **Developer Experience**
- **Clear organization**: Feature-first structure is intuitive
- **Reduced coupling**: Features are independent
- **Easier testing**: Each feature can be tested in isolation
- **Faster builds**: Smaller import graphs

### ✅ **Maintainability**
- **Single responsibility**: Each service has a clear purpose
- **Consistent patterns**: BaseService provides uniform behavior
- **Error handling**: Centralized exception management
- **Documentation**: Clear architecture boundaries

### ✅ **Scalability**
- **Feature teams**: Teams can work on features independently
- **Code reuse**: Shared infrastructure in `src/core/`
- **Future-proof**: Easy to add new features
- **Performance**: Optimized for large codebases

This architecture provides a solid foundation for the Krishi Link application while maintaining backward compatibility during the migration process.
