# Unified Product Management UI Components

This package provides reusable, modular components for product management that work for both Admin and Farmer users in the KrishiLink app.

## 🚀 Features

- **Reusable Components**: Modular widgets that can be used across different user roles
- **Role-based UI**: Automatically adapts based on user role (Admin vs Farmer)
- **Advanced Location Picker**: GPS location, geocoding, and Google Maps integration
- **Image Upload**: File picker with image preview
- **Form Validation**: Comprehensive form validation with error handling
- **Search & Filter**: Real-time search and category filtering
- **GetX Integration**: Reactive state management with GetX

## 📦 Components

### 1. ProductListScreen
Reusable list component with filtering, search, and role-based features.

```dart
ProductListScreen(
  products: controller.products,
  isLoading: controller.isLoading,
  isAdmin: true, // Show farmer names for admin
  title: 'manage_products',
  showActiveToggle: true, // Show active/inactive toggle
  onEdit: (product) => _editProduct(product),
  onDelete: (product) => _deleteProduct(product),
  onRefresh: () => _refreshProducts(),
  onToggleActive: (product, isActive) => _toggleActive(product, isActive),
  onAdd: () => _addProduct(),
)
```

### 2. ProductForm
Comprehensive form for adding/editing products with advanced location picker.

```dart
ProductForm(
  product: existingProduct, // null for add, Product for edit
  onSubmit: (formData, imagePath) {
    // Handle form submission
    controller.addProduct(formData, imagePath);
  },
  submitButtonText: 'Add Product',
)
```

### 3. ProductCard
Individual product card with expansion tile and action buttons.

```dart
ProductCard(
  product: product,
  isAdmin: true,
  showActiveToggle: true,
  onEdit: () => _editProduct(),
  onDelete: () => _deleteProduct(),
  onToggleActive: (isActive) => _toggleActive(isActive),
)
```

### 4. LocationPicker
Advanced location picker with GPS, geocoding, and Google Maps.

```dart
LocationPicker(
  initialLatitude: 27.7172,
  initialLongitude: 85.3240,
  initialAddress: 'Kathmandu, Nepal',
  onLocationSelected: (lat, lng, address) {
    // Handle location selection
  },
)
```

### 5. ProductFormData
Data transfer object for form handling.

```dart
ProductFormData formData = ProductFormData(
  productName: 'Organic Tomatoes',
  description: 'Fresh tomatoes',
  rate: 50.0,
  unit: 'kg',
  // ... other fields
);

// Create from existing product
ProductFormData.fromProduct(existingProduct);

// Validation
bool isValid = formData.isValid();
```

## 🎯 Usage Examples

### Admin Product Management

```dart
class AdminProductManagement extends StatelessWidget {
  final AdminProductController controller = Get.put(AdminProductController());

  @override
  Widget build(BuildContext context) {
    return ProductListScreen(
      products: controller.products,
      isLoading: controller.isLoading,
      isAdmin: true, // Show farmer names
      title: 'manage_products',
      showActiveToggle: true,
      onEdit: _editProduct,
      onDelete: _deleteProduct,
      onRefresh: _refreshProducts,
      onToggleActive: _toggleProductActive,
      onAdd: _addProduct,
    );
  }
}
```

### Farmer Product Management

```dart
class FarmerProductManagement extends StatelessWidget {
  final FarmerProductController controller = Get.put(FarmerProductController());

  @override
  Widget build(BuildContext context) {
    return ProductListScreen(
      products: controller.products,
      isLoading: controller.isLoading,
      isAdmin: false, // Don't show farmer names
      title: 'my_products',
      showActiveToggle: false, // Farmers don't need this
      onEdit: _editProduct,
      onDelete: _deleteProduct,
      onRefresh: _refreshProducts,
      onAdd: _addProduct,
    );
  }
}
```

### Unified Controller

```dart
class UnifiedProductController extends GetxController {
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentUserRole = ''.obs;

  // Automatically filter products based on user role
  RxList<Product> get userProducts => currentUserRole.value == 'admin'
      ? products // Admin sees all products
      : products.where((p) => p.farmerId == currentUserId.value).toList().obs;

  Future<void> addProduct(ProductFormData formData, String? imagePath) async {
    // Implementation
  }

  Future<void> updateProduct(String id, ProductFormData formData, String? imagePath) async {
    // Implementation
  }
}
```

## 🛠️ Setup Requirements

### Dependencies
Make sure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  get: ^4.7.2
  file_picker: ^10.1.9
  geolocator: ^14.0.2
  geocoding: ^4.0.0
  google_maps_flutter: ^2.12.3
  http: ^1.4.0
  path_provider: ^2.1.5
```

### Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to set product location.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to set product location.</string>
```

### Google Maps API Key
Add your Google Maps API key to:

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY_HERE"/>
```

#### iOS (`ios/Runner/AppDelegate.swift`)
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

## 🎨 Customization

### Theming
The components use your app's theme automatically. Customize colors in your `ThemeData`:

```dart
ThemeData(
  primaryColor: Colors.green,
  cardColor: Colors.white,
  // ... other theme properties
)
```

### Translations
Add these keys to your translation files:

```dart
// English
'manage_products': 'Manage Products',
'my_products': 'My Products',
'add_product': 'Add Product',
'edit_product': 'Edit Product',
'product_name': 'Product Name',
'description': 'Description',
'category': 'Category',
'rate': 'Rate',
'unit': 'Unit',
'available_quantity': 'Available Quantity',
'location': 'Location',
'latitude': 'Latitude',
'longitude': 'Longitude',
'pick_image': 'Pick Image',
'use_current_location': 'Use Current Location',
'search_location': 'Search Location',
'show_map': 'Show Map',
'hide_map': 'Hide Map',
'delete_product': 'Delete Product',
'confirm_delete_product': 'Are you sure you want to delete %s?',
'success': 'Success',
'error': 'Error',
'required': 'This field is required',
'invalid_rate': 'Please enter a valid rate',
'invalid_quantity': 'Please enter a valid quantity',
'image_required': 'Please select an image',
'location_required': 'Please select a location',
```

## 🔧 Integration with Existing Controllers

To integrate with your existing controllers, implement these methods:

```dart
class YourProductController extends GetxController {
  // Required methods for ProductListScreen
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> fetchProducts() async {
    // Your implementation
  }

  Future<void> addProduct(ProductFormData formData, String? imagePath) async {
    // Your implementation
  }

  Future<void> updateProduct(String id, ProductFormData formData, String? imagePath) async {
    // Your implementation
  }

  Future<void> deleteProduct(String id) async {
    // Your implementation
  }

  Future<void> updateProductActiveStatus(String id, bool isActive) async {
    // Your implementation (admin only)
  }
}
```

## 📱 Screenshots & Examples

Check the `examples/` folder for complete working examples:

- `admin_product_management.dart` - Admin-specific implementation
- `farmer_product_management.dart` - Farmer-specific implementation
- `unified_product_management_example.dart` - Complete unified example

## 🤝 Contributing

1. Follow the existing code style
2. Add tests for new features
3. Update documentation
4. Ensure all examples work

## 📄 License

This component library is part of the KrishiLink project.