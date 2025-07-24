import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:krishi_link/core/components/product/product_form_data.dart';
import 'package:krishi_link/features/admin/models/product_model.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/components/product/location_picker.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/components/product/examples/unified_product_controller.dart';
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
  final RxBool isSubmitting = false.obs;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _initializeForm();
    final user = authController.currentUser.value;
    userRole = user?.role.toLowerCase() ?? '';
    if (userRole == 'farmer') {
      farmerContact =
          user?.email?.isNotEmpty == true ? user?.email : user?.phoneNumber;
      farmerContactController.text = farmerContact ?? '';
    } else if (widget.product != null && widget.product!.farmerPhone != null) {
      farmerContactController.text = widget.product!.farmerPhone!;
    }
  }

  void _initializeForm() {
    formData =
        widget.product != null
            ? ProductFormData.fromProduct(widget.product!)
            : ProductFormData();
    productNameController.text = formData.productName;
    descriptionController.text = formData.description;
    rateController.text = formData.rate > 0 ? formData.rate.toString() : '';
    quantityController.text =
        formData.availableQuantity > 0
            ? formData.availableQuantity.toString()
            : '';
    categoryController.text = formData.category;
    unit.value = formData.unit;
    if (widget.product != null) {
      _downloadImage();
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
        PopupService.success('image_downloaded'.tr);
      } else {
        PopupService.error(
          'failed_to_download_image'.trParams({
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      formData.productName = productNameController.text.trim();
      formData.description = descriptionController.text.trim();
      formData.rate = double.tryParse(rateController.text) ?? 0;
      formData.availableQuantity =
          double.tryParse(quantityController.text) ?? 0;
      formData.category = categoryController.text.trim();
      formData.unit = unit.value;
      formData.farmerContact = farmerContactController.text.trim();
      if (widget.product == null && imageFile == null) {
        PopupService.error('image_required'.tr);
        return;
      }
      if (formData.latitude == 0 || formData.longitude == 0) {
        PopupService.error('location_required'.tr);
        return;
      }
      isSubmitting.value = true;
      try {
        if (userRole == 'admin') {
          final userDetails = await unifiedProductController
              .fetchUserDetailsByEmailOrPhone(formData.farmerContact);
          if (userDetails == null) {
            PopupService.error('user_not_found'.tr);
            isSubmitting.value = false;
            return;
          }
          // Only sending email or phone as required
        }
        await widget.onSubmit(formData, newImagePath);
      } catch (e) {
        PopupService.error(e.toString());
      } finally {
        isSubmitting.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.product == null ? 'add_product'.tr : 'edit_product'.tr,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: 20,
                      child: Icon(
                        Icons.agriculture_outlined,
                        size: 100,
                        color: colorScheme.onPrimary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
            labelText: 'product_name'.tr,
            icon: Icons.inventory_outlined,
            maxLength: 50,
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
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
            labelText: 'category'.tr,
            icon: Icons.category_outlined,
            maxLength: 50,
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: farmerContactController,
            labelText: 'farmer_contact'.tr,
            icon: Icons.person_outline,
            readOnly: userRole == 'farmer',
            hintText:
                userRole == 'admin' ? 'Enter farmer phone or email' : null,
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ColorScheme colorScheme) {
    return _buildAnimatedCard(
      colorScheme: colorScheme,
      icon: Icons.attach_money_outlined,
      title: 'pricing_quantity'.tr,
      iconColor: Colors.green,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildEnhancedTextField(
                  controller: rateController,
                  labelText: 'rate'.tr,
                  icon: Icons.currency_rupee_outlined,
                  prefixText: 'Rs. ',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator:
                      (v) =>
                          (v == null ||
                                  double.tryParse(v) == null ||
                                  double.parse(v) <= 0)
                              ? 'invalid_rate'.tr
                              : double.parse(v) > 99999.99
                              ? 'rate_max_99999_99'.tr
                              : null,
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
                    labelText: 'unit'.tr,
                    icon: Icons.straighten_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildEnhancedTextField(
            controller: quantityController,
            labelText: 'available_quantity'.tr,
            icon: Icons.inventory_2_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator:
                (v) =>
                    (v == null ||
                            double.tryParse(v) == null ||
                            double.parse(v) < 0)
                        ? 'invalid_quantity'.tr
                        : double.parse(v) > 99999.99
                        ? 'quantity_max_99999_99'.tr
                        : null,
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
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
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
                          color: Colors.black.withOpacity(0.1),
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
                                color: colorScheme.surfaceVariant,
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                  'image_requirements'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
      color: colorScheme.surfaceVariant,
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 60,
        color: colorScheme.onSurfaceVariant,
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
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
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
                    color: iconColor.withOpacity(0.1),
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
        ).colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
        ).colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
    return Obx(
      () => Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isSubmitting.value ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child:
              isSubmitting.value
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
      ),
    );
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
