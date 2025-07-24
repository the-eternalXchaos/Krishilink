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

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late ProductFormData formData;
  String? newImagePath; // Track if image changed
  File? imageFile; // Temporary file for downloaded or picked image
  final RxString unit = 'kg'.obs;
  final RxBool isLoadingImage = false.obs;
  final RxBool isSubmitting = false.obs;

  // Controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController farmerContactController = TextEditingController();

  final AuthController authController = Get.find<AuthController>();
  late final String userRole;
  late final String? farmerContact;

  @override
  void initState() {
    super.initState();
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
        await widget.onSubmit(formData, newImagePath);
        // Optionally: Get.back(); // If you want to close the form here
      } catch (e) {
        // Optionally: show error
      } finally {
        isSubmitting.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'add_product'.tr : 'edit_product'.tr,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildPricingSection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'basic_information'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: productNameController,
              decoration: InputDecoration(
                labelText: 'product_name'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory),
              ),
              maxLength: 50,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'description'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLength: 300,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: 'category'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
              maxLength: 50,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: farmerContactController,
              readOnly: userRole == 'farmer',
              decoration: InputDecoration(
                labelText: 'farmer_contact'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                hintText:
                    userRole == 'admin' ? 'Enter farmer phone or email' : null,
              ),
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'pricing_quantity'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: rateController,
                    decoration: InputDecoration(
                      labelText: 'rate'.tr,
                      border: const OutlineInputBorder(),
                      prefixText: 'Rs. ',
                      prefixIcon: const Icon(Icons.currency_rupee),
                    ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: unit.value,
                      items:
                          ['kg', 'liter', 'piece']
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.tr),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          unit.value = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'unit'.tr,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                      validator: (v) => v == null ? 'required'.tr : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'available_quantity'.tr,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product_image'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(
                    () =>
                        isLoadingImage.value
                            ? const Center(child: CircularProgressIndicator())
                            : imageFile != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                              ),
                            )
                            : formData.imagePath.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                formData.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                              ),
                            )
                            : const Icon(Icons.add_photo_alternate, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera),
                        label: Text('pick_image'.tr),
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'image_requirements'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'location_information'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LocationPicker(
              initialLatitude: formData.latitude,
              initialLongitude: formData.longitude,
              initialAddress: formData.location.toString(),
              onLocationSelected: _onLocationSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isSubmitting.value ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              isSubmitting.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    widget.submitButtonText.isNotEmpty
                        ? widget.submitButtonText
                        : widget.product == null
                        ? 'add_product'.tr
                        : 'update_product'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    productNameController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    quantityController.dispose();
    categoryController.dispose();
    farmerContactController.dispose();
    super.dispose();
  }
}
