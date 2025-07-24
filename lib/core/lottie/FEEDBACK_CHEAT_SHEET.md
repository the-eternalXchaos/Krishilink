# 🎪 Feedback System Cheat Sheet

## 🚀 Quick Start (One Line)

```dart
// Basic feedback
PopupService.success('Operation completed');
PopupService.error('Something went wrong');
PopupService.warning('Please check input');
PopupService.info('Processing...');

// Specific actions
PopupService.addedToCart('Product added to cart');
PopupService.orderPlaced('Order confirmed');
PopupService.party('Congratulations!');
```

## 🎭 Popup vs Snackbar Decision

| Type | Shows As | When To Use |
|------|----------|-------------|
| `success` | 🎪 **Popup** | Important success (product added, order placed) |
| `error` | 🎪 **Popup** | Critical errors (failed operations) |
| `warning` | 🎪 **Popup** | Important warnings (validation errors) |
| `orderPlaced` | 🎪 **Popup** | Order confirmations |
| `party` | 🎪 **Popup** | Celebrations |
| `info` | 🍿 **Snackbar** | General information |
| `addedToCart` | 🍿 **Snackbar** | Cart operations |
| `userLoading` | 🍿 **Snackbar** | User status updates |

## 🎯 Migration Patterns

### ❌ Old Way → ✅ New Way

```dart
// Error
Get.snackbar('error'.tr, 'Failed to load data', backgroundColor: Colors.red.shade700);
PopupService.error('Failed to load data');

// Success
Get.snackbar('success'.tr, 'Product added', backgroundColor: Colors.green.shade700);
PopupService.success('Product added');

// Warning
Get.snackbar('warning'.tr, 'Fill all fields', backgroundColor: Colors.orange.shade700);
PopupService.warning('Fill all fields');

// Cart
Get.snackbar('Added to Cart', 'Product added to cart');
PopupService.addedToCart('Product added to cart');
```

## 🎪 Advanced Usage

### Force Popup
```dart
PopupService.handleFeedback(
  title: 'Important',
  message: 'This will show as popup',
  type: PopupType.info,
  forcePopup: true,
);
```

### Force Snackbar
```dart
PopupService.showSnackbar(
  title: 'Success',
  message: 'This will show as snackbar',
  type: PopupType.success,
);
```

### Custom Duration
```dart
PopupService.handleFeedback(
  title: 'Processing',
  message: 'This will stay longer',
  type: PopupType.info,
  duration: Duration(seconds: 10),
);
```

## 🤖 Natural Language (AI-friendly)

```dart
// AI can use these
PopupService.showFeedback('Show success message: Product added to cart');
PopupService.showFeedback('Show error: Failed to place order');
PopupService.showFeedback('Alert warning: Low internet connection');
PopupService.showFeedback('Display order placed confirmation in center with animation');
```

## 🎨 Visual Features

### Colors
- ✅ **Success**: Green
- ❌ **Error**: Red  
- ⚠️ **Warning**: Orange
- ℹ️ **Info**: Blue
- 🛒 **Cart**: Teal
- 📦 **Order**: Purple
- 🎉 **Party**: Purple

### Durations
- **Error**: 5 seconds
- **Success**: 3 seconds
- **Warning**: 4 seconds
- **Info**: 3 seconds
- **Cart**: 3 seconds
- **Order**: 4 seconds

### Icons
- ✅ Success: `Icons.check_circle`
- ❌ Error: `Icons.error_outline`
- ⚠️ Warning: `Icons.warning`
- ℹ️ Info: `Icons.info`
- 🛒 Cart: `Icons.shopping_cart`
- 📦 Order: `Icons.shopping_bag`
- 🎉 Party: `Icons.celebration`

## 📱 Import

```dart
import 'package:krishi_link/core/lottie/popup_service.dart';
```

## 🎯 Common Use Cases

### Authentication
```dart
PopupService.success('Welcome back!');
PopupService.error('Invalid credentials');
PopupService.warning('Please login first');
```

### Products
```dart
PopupService.success('Product added successfully');
PopupService.error('Failed to load products');
PopupService.addedToCart('Product added to cart');
```

### Orders
```dart
PopupService.orderPlaced('Order confirmed successfully');
PopupService.error('Failed to place order');
PopupService.party('Congratulations on your first order!');
```

### Validation
```dart
PopupService.warning('Please fill all required fields');
PopupService.error('Invalid email format');
PopupService.info('Checking availability...');
```

## 🔄 Find & Replace Commands

```bash
# Error messages
Find: Get\.snackbar\('error'\.tr, '([^']+)'
Replace: PopupService.error('$1')

# Success messages  
Find: Get\.snackbar\('success'\.tr, '([^']+)'
Replace: PopupService.success('$1')

# Warning messages
Find: Get\.snackbar\('warning'\.tr, '([^']+)'
Replace: PopupService.warning('$1')

# Cart messages
Find: Get\.snackbar\('Added to Cart', '([^']+)'
Replace: PopupService.addedToCart('$1')
```

## 🎉 Benefits

- ✅ **One line** instead of 5-6 lines
- ✅ **Consistent** styling everywhere
- ✅ **Beautiful** Lottie animations
- ✅ **Intelligent** popup vs snackbar decisions
- ✅ **AI-friendly** natural language support
- ✅ **Easy** to maintain and update

---

**Happy coding! 🚀** 