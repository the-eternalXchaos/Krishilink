// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_link/core/lottie/pop_up.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:path_provider/path_provider.dart';
import 'package:krishi_link/src/core/components/product/product_form_data.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/src/core/components/product/location_picker.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/core/components/product/management/unified_product_controller.dart';
import 'package:image_picker/image_picker.dart';

class ProductForm extends StatefulWidget {
  final Product? product; // null means add, non-null means edit
  final Future<void> Function(ProductFormData formData, String? imagePath)
  onSubmit;
  final String submitButtonText;

  const ProductForm({
    super.key,
    this.product,
    required this.onSubmit,
    this.submitButtonText = '',
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late ProductFormData formData;
  String? newImagePath; // Track if image changed
  File? imageFile; // Temporary file for downloaded or picked image
  final RxString unit = 'kg'.obs;
  final RxBool isLoadingImage = false.obs;
  late AnimationController _animationController;
  // TODO: Unused animation - commented out to resolve lint warnings
  // late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController farmerContactController = TextEditingController();

  final AuthController authController = Get.find<AuthController>();
  final unifiedProductController = Get.find<UnifiedProductController>();
  late final String userRole;
  late final String? farmerContact;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '🔄 [ProductForm] initState called for product: ${widget.product?.productName ?? 'new product'}',
    );

    try {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      // TODO: Unused animation - commented out to resolve lint warnings
      // _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      //   CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      // );
      _animationController.forward();
      debugPrint('✅ [ProductForm] Animation controller initialized');

      _initializeForm();
      debugPrint('✅ [ProductForm] Form initialized');

      final user = authController.currentUser.value;
      userRole = user?.role.toLowerCase() ?? '';
      debugPrint('🔄 [ProductForm] User role: $userRole');

      if (userRole == 'farmer') {
        farmerContact =
            user?.email?.isNotEmpty == true ? user?.email : user?.phoneNumber;
        farmerContactController.text = farmerContact ?? '';
        debugPrint('🔄 [ProductForm] Farmer contact set: $farmerContact');
      } else if (widget.product != null &&
          widget.product!.farmerPhone != null) {
        farmerContactController.text = widget.product!.farmerPhone!;
        debugPrint(
          '🔄 [ProductForm] Product farmer contact set: ${widget.product!.farmerPhone}',
        );
      }

      debugPrint('✅ [ProductForm] initState completed successfully');
    } catch (e) {
      debugPrint('❌ [ProductForm] Error in initState: $e');
      // Don't rethrow - let the form continue to render
    }
  }

  void _initializeForm() {
    debugPrint('🔄 [ProductForm] _initializeForm called');
    try {
      formData =
          widget.product != null
              ? ProductFormData.fromProduct(widget.product!)
              : ProductFormData();
      debugPrint(
        '✅ [ProductForm] FormData created: ${formData.productName}, ${formData.rate}, ${formData.category}',
      );

      productNameController.text = formData.productName;
      descriptionController.text = formData.description;
      rateController.text = formData.rate > 0 ? formData.rate.toString() : '';
      quantityController.text =
          formData.availableQuantity > 0
              ? formData.availableQuantity.toString()
              : '';
      categoryController.text = formData.category;
      unit.value = formData.unit;

      debugPrint('✅ [ProductForm] Controllers initialized');

      if (widget.product != null) {
        debugPrint('🔄 [ProductForm] Product exists, downloading image');
        _downloadImage();
      } else {
        debugPrint('🔄 [ProductForm] New product, no image to download');
      }

      debugPrint('✅ [ProductForm] _initializeForm completed successfully');
    } catch (e) {
      debugPrint('❌ [ProductForm] Error in _initializeForm: $e');
      // Don't rethrow - let the form continue to render
    }
  }

  Future<void> _downloadImage() async {
    if (widget.product?.image.isEmpty ?? true) return;
    try {
      isLoadingImage.value = true;
      final response = await http.get(Uri.parse(widget.product!.image));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.product!.id}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          imageFile = file;
          newImagePath = file.path;
          formData.imagePath = widget.product!.image;
        });
        PopupService.showSnackbar(
          type: PopupType.success,
          title: 'image_downloaded'.tr,
          message: 'image_downloaded',
        );
      } else {
        PopupService.showSnackbar(
          type: PopupType.error,
          title: 'failed_to_download_image'.tr,
          message: 'failed_to_download_image'.trParams({
            'error': 'Status ${response.statusCode}',
          }),
        );
      }
    } catch (e) {
      PopupService.error(
        'failed_to_download_image'.trParams({'error': e.toString()}),
      );
    } finally {
      isLoadingImage.value = false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() {
          imageFile = File(result.files.single.path!);
          newImagePath = imageFile!.path;
          formData.imagePath = newImagePath!;
        });
        PopupService.success('image_selected'.tr);
      }
    } catch (e) {
      PopupService.error(
        'failed_to_pick_image'.trParams({'error': e.toString()}),
      );
    }
  }

  // Add this method for camera capture
  Future<void> _captureImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          imageFile = File(pickedFile.path);
          newImagePath = imageFile!.path;
          formData.imagePath = newImagePath!;
        });
        PopupService.success('image_captured'.tr);
      }
    } catch (e) {
      PopupService.error(
        'failed_to_capture_image'.trParams({'error': e.toString()}),
      );
    }
  }

  void _onLocationSelected(double latitude, double longitude, String address) {
    setState(() {
      formData.latitude = latitude;
      formData.longitude = longitude;
      formData.location = address;
    });
  }

  void _submitForm() async {
    debugPrint('🔄 [ProductForm] _submitForm called');

    // Collect validation errors (keep your existing validation)
    final errors = <String>[];
    if (productNameController.text.trim().isEmpty) {
      errors.add('Product Name');
    } else if (productNameController.text.trim().length < 2) {
      errors.add('Product Name (must be at least 2 characters)');
    }
    if (categoryController.text.trim().isEmpty) errors.add('Category');
    if (farmerContactController.text.trim().isEmpty) {
      errors.add('Farmer Contact');
    }

    if (rateController.text.trim().isEmpty) {
      errors.add('Rate');
    } else {
      final rate = double.tryParse(rateController.text);
      if (rate == null) {
        errors.add('Rate (must be a valid number)');
      } else if (rate <= 0) {
        errors.add('Rate (must be greater than 0)');
      } else if (rate > 99999.99) {
        errors.add('Rate (cannot exceed Rs. 99,999.99)');
      }
    }
    if (quantityController.text.trim().isEmpty) {
      errors.add('Available Quantity');
    } else {
      final qty = double.tryParse(quantityController.text);
      if (qty == null) {
        errors.add('Available Quantity (must be a valid number)');
      } else if (qty < 0) {
        errors.add('Available Quantity (cannot be negative)');
      } else if (qty > 99999.99)
        errors.add('Available Quantity (cannot exceed 99,999.99)');
    }

    if (widget.product == null && imageFile == null) {
      errors.add('Product Image (required for new products)');
    }
    if (formData.latitude == 0 || formData.longitude == 0) {
      errors.add('Location (please select a valid location)');
    }

    if (errors.isNotEmpty) {
      debugPrint('❌ [ProductForm] Validation failed: $errors');

      PopupService.showSnackbar(
        type: PopupType.error,
        title: 'validation_error'.tr,
        message: errors.map((e) => '• $e').join('\n'),
      );
      PopupService.error(
        'Please fill the following required fields:\n${errors.map((e) => '• $e').join('\n')}',
        title: 'Missing Information',
      );
      return;
    }

    debugPrint('✅ [ProductForm] Form validation passed');

    // Map controllers → formData
    formData
      ..productName = productNameController.text.trim()
      ..description = descriptionController.text.trim()
      ..rate = double.tryParse(rateController.text) ?? 0
      ..availableQuantity = double.tryParse(quantityController.text) ?? 0
      ..category = categoryController.text.trim()
      ..unit = unit.value
      ..farmerContact = farmerContactController.text.trim();

    debugPrint('🔄 [ProductForm] Form data prepared');
    debugPrint('  - Product Name: ${formData.productName}');
    debugPrint('  - Rate: ${formData.rate}');
    debugPrint('  - Category: ${formData.category}');
    debugPrint('  - Available Quantity: ${formData.availableQuantity}');
    debugPrint('  - Unit: ${formData.unit}');
    debugPrint('  - Description: ${formData.description}');
    debugPrint('  - Farmer Contact: ${formData.farmerContact}');
    debugPrint('  - Latitude: ${formData.latitude}');
    debugPrint('  - Longitude: ${formData.longitude}');
    debugPrint('  - Image File: ${imageFile?.path}');
    debugPrint('  - New Image Path: $newImagePath');

    // Replace the existing _submitForm method's try-catch block with this:
    try {
      if (userRole == 'admin') {
        debugPrint('🔄 [ProductForm] Admin user, checking farmer details');
        final userDetails = await unifiedProductController
            .fetchUserDetailsByEmailOrPhone(formData.farmerContact);
        if (userDetails == null) {
          PopupService.error('user_not_found'.tr);
          return;
        }
      }

      debugPrint('🔄 [ProductForm] About to call controller update');
      if (widget.product != null) {
        // Call controller's updateProduct method directly
        await unifiedProductController.updateProduct(
          widget.product!.id,
          formData,
          newImagePath,
        );
      }

      debugPrint('🔄 [ProductForm] About to call widget.onSubmit');
      await widget.onSubmit(formData, newImagePath);
      debugPrint('✅ [ProductForm] onSubmit completed successfully');

      if (!mounted) return;
      debugPrint('🔄 [ProductForm] Closing form/dialog');
      Get.back();
    } catch (e, st) {
      debugPrint('❌ [ProductForm] Error in onSubmit: $e');
      debugPrint('❌ [ProductForm] Stack: $st');
      PopupService.error('Failed to save product: $e');
    }
  }

  // void _submitForm() async {
  //   debugPrint('🔄 [ProductForm] _submitForm called');

  //   // Collect validation errors
  //   final errors = <String>[];

  //   // Validate fields
  //   if (productNameController.text.trim().isEmpty) {
  //     errors.add('Product Name');
  //   } else if (productNameController.text.trim().length < 2) {
  //     errors.add('Product Name (must be at least 2 characters)');
  //   }

  //   if (categoryController.text.trim().isEmpty) {
  //     errors.add('Category');
  //   }

  //   if (farmerContactController.text.trim().isEmpty) {
  //     errors.add('Farmer Contact');
  //   }

  //   if (rateController.text.trim().isEmpty) {
  //     errors.add('Rate');
  //   } else {
  //     final rate = double.tryParse(rateController.text);
  //     if (rate == null) {
  //       errors.add('Rate (must be a valid number)');
  //     } else if (rate <= 0) {
  //       errors.add('Rate (must be greater than 0)');
  //     } else if (rate > 99999.99) {
  //       errors.add('Rate (cannot exceed Rs. 99,999.99)');
  //     }
  //   }

  //   if (quantityController.text.trim().isEmpty) {
  //     errors.add('Available Quantity');
  //   } else {
  //     final quantity = double.tryParse(quantityController.text);
  //     if (quantity == null) {
  //       errors.add('Available Quantity (must be a valid number)');
  //     } else if (quantity < 0) {
  //       errors.add('Available Quantity (cannot be negative)');
  //     } else if (quantity > 99999.99) {
  //       errors.add('Available Quantity (cannot exceed 99,999.99)');
  //     }
  //   }

  //   if (widget.product == null && imageFile == null) {
  //     errors.add('Product Image (required for new products)');
  //   }

  //   if (formData.latitude == 0 || formData.longitude == 0) {
  //     errors.add('Location (please select a valid location)');
  //   }

  //   // Check if there are any errors
  //   if (errors.isNotEmpty) {
  //     debugPrint('❌ [ProductForm] Validation failed: $errors');
  //     PopupService.error(
  //       'Please fill the following required fields:\n${errors.map((e) => '• $e').join('\n')}',
  //       title: 'Missing Information',
  //     );
  //     return;
  //   }

  //   debugPrint('✅ [ProductForm] Form validation passed');

  //   formData.productName = productNameController.text.trim();
  //   formData.description = descriptionController.text.trim();
  //   formData.rate = double.tryParse(rateController.text) ?? 0;
  //   formData.availableQuantity = double.tryParse(quantityController.text) ?? 0;
  //   formData.category = categoryController.text.trim();
  //   formData.unit = unit.value;
  //   formData.farmerContact = farmerContactController.text.trim();

  //   debugPrint('🔄 [ProductForm] Form data prepared:');
  //   debugPrint('  - Product Name: ${formData.productName}');
  //   debugPrint('  - Rate: ${formData.rate}');
  //   debugPrint('  - Category: ${formData.category}');
  //   debugPrint('  - Available Quantity: ${formData.availableQuantity}');
  //   debugPrint('  - Unit: ${formData.unit}');
  //   debugPrint('  - Description: ${formData.description}');
  //   debugPrint('  - Farmer Contact: ${formData.farmerContact}');
  //   debugPrint('  - Latitude: ${formData.latitude}');
  //   debugPrint('  - Longitude: ${formData.longitude}');
  //   debugPrint('  - Image File: ${imageFile?.path}');
  //   debugPrint('  - New Image Path: $newImagePath');

  //   // Remove manual loading state management - now handled by management layer
  //   debugPrint('🔄 [ProductForm] Starting form submission process');

  //   try {
  //     await Future.delayed(const Duration(seconds: 1));
  //     if (userRole == 'admin') {
  //       debugPrint('🔄 [ProductForm] Admin user, checking farmer details');
  //       final userDetails = await unifiedProductController
  //           .fetchUserDetailsByEmailOrPhone(formData.farmerContact);
  //       if (userDetails == null) {
  //         debugPrint('❌ [ProductForm] User not found');
  //         PopupService.error('user_not_found'.tr);
  //         return;
  //       }
  //       debugPrint('✅ [ProductForm] Farmer details found');
  //     }

  //     debugPrint('🔄 [ProductForm] About to call widget.onSubmit');
  //     debugPrint(
  //       '🔄 [ProductForm] widget.onSubmit type: ${widget.onSubmit.runtimeType}',
  //     );
  //     await widget.onSubmit(formData, newImagePath);
  //     debugPrint('✅ [ProductForm] onSubmit completed successfully');

  //     if (unifiedProductController.isLoading.value) {
  //       debugPrint(
  //         '⚠️ [ProductForm] Form submission blocked: isLoading is true',
  //       );
  //       PopupService.error('Please wait for the current request to finish.');
  //       return;
  //     }
  //     debugPrint('🔄 [ProductForm] _submitForm called');
  //     try {
  //       debugPrint('🔄 [ProductForm] About to call widget.onSubmit');
  //       debugPrint(
  //         '🔄 [ProductForm] widget.onSubmit type: ${widget.onSubmit.runtimeType}',
  //       );
  //       await widget.onSubmit(formData, newImagePath);
  //       debugPrint('✅ [ProductForm] onSubmit completed successfully');
  //     } catch (e) {
  //       debugPrint('❌ [ProductForm] Error in onSubmit: $e');
  //       debugPrint('❌ [ProductForm] Error type: ${e.runtimeType}');
  //       debugPrint('❌ [ProductForm] Error stack trace: ${e.toString()}');
  //       PopupService.error('Failed to save product: ${e.toString()}');
  //     }
  //     // Close the form/dialog
  //     debugPrint('🔄 [ProductForm] Closing form/dialog');
  //     Get.back();
  //   } catch (e) {
  //     debugPrint('❌ [ProductForm] Error in onSubmit: $e');
  //     debugPrint('❌ [ProductForm] Error type: ${e.runtimeType}');
  //     debugPrint('❌ [ProductForm] Error stack trace: ${e.toString()}');
  //     PopupService.error('Failed to save product: ${e.toString()}');
  //   }
  //   // Note: Loading state is now managed by the management layer
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Add Product' : 'Update Product',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildPricingSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildImageSection(colorScheme),
                    const SizedBox(height: 24),
                    _buildLocationSection(colorScheme),
                    const SizedBox(height: 32),
                    _buildSubmitButton(colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Loading overlay
            Obx(
              () =>
                  unifiedProductController.isLoading.value
                      ? Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Card(
                            elevation: 8,
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    return _buildAnimatedCard(
      colorScheme: colorScheme,
      icon: Icons.info_outline,
      title: 'basic_information'.tr,
      iconColor: Colors.blue,
      child: Column(
        children: [
          _buildEnhancedTextField(
            controller: productNameController,
            labelText: 'Product Name required',
            icon: Icons.inventory_2_outlined,
            maxLength: 100,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a product name';
              }
              if (v.trim().length < 2) {
                return 'Product name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: descriptionController,
            labelText: 'description'.tr,
            icon: Icons.description_outlined,
            maxLength: 300,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: categoryController,
            labelText: 'Category *',
            icon: Icons.category_outlined,
            maxLength: 50,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: farmerContactController,
            labelText: 'Farmer Contact *',
            icon: Icons.person_outline,
            readOnly: userRole == 'farmer',
            hintText:
                userRole == 'admin' ? 'Enter farmer phone or email' : null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter farmer contact information';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ColorScheme colorScheme) {
    return _buildAnimatedCard(
      colorScheme: colorScheme,
      icon: Icons.attach_money_outlined,
      title: 'Pricing & Quantity',
      iconColor: Colors.green,
      child: Column(
        children: [
          // Rate and Unit in a responsive row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Wide screen: side by side
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildEnhancedTextField(
                        controller: rateController,
                        labelText: 'Rate *',
                        icon: Icons.currency_rupee_outlined,
                        prefixText: 'Rs. ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a rate';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(v) <= 0) {
                            return 'Rate must be greater than 0';
                          }
                          if (double.parse(v) > 99999.99) {
                            return 'Rate cannot exceed Rs. 99,999.99';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => _buildEnhancedDropdown(
                          value: unit.value,
                          items: ['kg', 'liter', 'piece'],
                          onChanged: (value) {
                            if (value != null) {
                              unit.value = value;
                            }
                          },
                          labelText: 'Unit',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow screen: stacked
                return Column(
                  children: [
                    _buildEnhancedTextField(
                      controller: rateController,
                      labelText: 'Rate *',
                      icon: Icons.currency_rupee_outlined,
                      prefixText: 'Rs. ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a rate';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(v) <= 0) {
                          return 'Rate must be greater than 0';
                        }
                        if (double.parse(v) > 99999.99) {
                          return 'Rate cannot exceed Rs. 99,999.99';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => _buildEnhancedDropdown(
                        value: unit.value,
                        items: ['kg', 'liter', 'piece'],
                        onChanged: (value) {
                          if (value != null) {
                            unit.value = value;
                          }
                        },
                        labelText: 'Unit',
                        icon: Icons.straighten_outlined,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: quantityController,
            labelText: 'Available Quantity *',
            icon: Icons.inventory_2_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter available quantity';
              }
              if (double.tryParse(v) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(v) < 0) {
                return 'Quantity cannot be negative';
              }
              if (double.parse(v) > 99999.99) {
                return 'Quantity cannot exceed 99,999.99';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ColorScheme colorScheme) {
    return _buildAnimatedCard(
      colorScheme: colorScheme,
      icon: Icons.photo_camera_outlined,
      title: 'product_image'.tr,
      iconColor: Colors.purple,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Obx(
                  () => Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          isLoadingImage.value
                              ? Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : imageFile != null
                              ? Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildImagePlaceholder(colorScheme),
                              )
                              : formData.imagePath.isNotEmpty
                              ? Image.network(
                                formData.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildImagePlaceholder(colorScheme),
                              )
                              : _buildImagePlaceholder(colorScheme),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.image_outlined),
                        label: Text('pick_image'.tr),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text('capture_image'.tr),
                        onPressed: _captureImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.product == null
                      ? 'Please select an image for your product'
                      : 'Product image (optional for updates)',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        widget.product == null
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                    fontWeight:
                        widget.product == null
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 60,
            color:
                widget.product == null
                    ? Colors.orange.shade600
                    : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            widget.product == null ? 'Select Image' : 'No Image Selected',
            style: TextStyle(
              fontSize: 14,
              color:
                  widget.product == null
                      ? Colors.orange.shade700
                      : colorScheme.onSurfaceVariant,
              fontWeight:
                  widget.product == null ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(ColorScheme colorScheme) {
    return _buildAnimatedCard(
      colorScheme: colorScheme,
      icon: Icons.location_on_outlined,
      title: 'location_information'.tr,
      iconColor: Colors.red,
      child: LocationPicker(
        initialLatitude: formData.latitude,
        initialLongitude: formData.longitude,
        initialAddress: formData.location.toString(),
        onLocationSelected: _onLocationSelected,
      ),
    );
  }

  Widget _buildAnimatedCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? hintText,
    String? prefixText,
    int? maxLength,
    int? maxLines,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
    );
  }

  Widget _buildEnhancedDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String labelText,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items
              .map(
                (item) => DropdownMenuItem(value: item, child: Text(item.tr)),
              )
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      validator: (v) => v == null ? 'required'.tr : null,
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return Obx(() {
      final loading = unifiedProductController.isLoading.value;
      final colors =
          loading
              ? [
                colorScheme.primary.withValues(alpha: 0.5),
                colorScheme.primary.withValues(alpha: 0.3),
              ]
              : [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.8),
              ];

      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: loading ? 0.1 : 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              unifiedProductController.isLoading.value ? null : _submitForm,

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child:
              loading
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.product == null ? Icons.add : Icons.update,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.submitButtonText.isNotEmpty
                            ? widget.submitButtonText
                            : widget.product == null
                            ? 'add_product'.tr
                            : 'update_product'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    productNameController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    quantityController.dispose();
    categoryController.dispose();
    farmerContactController.dispose();
    super.dispose();
  }
}
