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

class AddEditProductForm extends StatefulWidget {
  final Product? product; // null means add, non-null means edit
  final void Function(ProductFormData formData, String? newImagePath) onSubmit;

  const AddEditProductForm({super.key, this.product, required this.onSubmit});

  @override
  _AddEditProductFormState createState() => _AddEditProductFormState();
}

class _AddEditProductFormState extends State<AddEditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late ProductFormData formData;
  String? newImagePath; // Track if image changed for ML validation
  File? imageFile; // Temporary file for downloaded or picked image
  final RxString unit = 'kg'.obs;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final RxBool isLoadingImage = false.obs;

  @override
  void initState() {
    super.initState();
    formData =
        widget.product != null
            ? ProductFormData.fromProduct(widget.product!)
            : ProductFormData();
    if (widget.product != null) {
      // locationController.text = formData.location;
      latitudeController.text = formData.latitude.toString();
      longitudeController.text = formData.longitude.toString();
      unit.value = formData.unit;
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
        await file.write(response.bodyBytes);
        setState(() {
          imageFile = file;
          newImagePath = file.path;
          formData.imagePath = widget.product!.image;
        });
        Get.snackbar('success'.tr, 'image_downloaded'.tr);
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_download_image'.trParams({
            'error': 'Status ${response.statusCode}',
          }),
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
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
        Get.snackbar('success'.tr, 'image_selected'.tr);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.trParams({'error': e.toString()}),
      );
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      Get.snackbar('error'.tr, 'enter_location_to_search'.tr);
      return;
    }
    try {
      final locations = await locationFromAddress(
        query,
      ); // <-- Removed localeIdentifier
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          formData.location = query;
          formData.latitude = location.latitude;
          formData.longitude = location.longitude;
          locationController.text = query;
          latitudeController.text = location.latitude.toString();
          longitudeController.text = location.longitude.toString();
        });
        Get.snackbar(
          'success'.tr,
          'location_found'.trParams({
            'address': query,
            'lat': location.latitude.toString(),
            'lon': location.longitude.toString(),
          }),
        );
      } else {
        Get.snackbar('error'.tr, 'no_location_found'.tr);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_search_location'.trParams({'error': e.toString()}),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (await Geolocator.requestPermission() !=
                LocationPermission.whileInUse &&
            await Geolocator.requestPermission() != LocationPermission.always) {
          Get.snackbar('error'.tr, 'location_services_disabled'.tr);
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('error'.tr, 'location_permission_denied'.tr);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('error'.tr, 'location_permission_denied_forever'.tr);
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      final address =
          placemark != null
              ? '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}'
              : 'Unknown location';

      setState(() {
        formData.location = address;
        formData.latitude = position.latitude;
        formData.longitude = position.longitude;
        locationController.text = address;
        latitudeController.text = position.latitude.toString();
        longitudeController.text = position.longitude.toString();
      });

      Get.snackbar(
        'success'.tr,
        'current_location_fetched'.trParams({
          'address': address,
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
        }),
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_get_location'.trParams({'error': e.toString()}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            TextFormField(
              initialValue: formData.productName,
              decoration: InputDecoration(
                labelText: 'product_name'.tr,
                border: OutlineInputBorder(),
                errorText:
                    formData.productName.length > 50
                        ? 'max_50_characters'.tr
                        : null,
              ),
              maxLength: 50,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              onSaved: (v) => formData.productName = v!.trim(),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              initialValue: formData.description,
              decoration: InputDecoration(
                labelText: 'description'.tr,
                border: OutlineInputBorder(),
                errorText:
                    formData.description.length > 300
                        ? 'max_300_characters'.tr
                        : null,
              ),
              maxLength: 300,
              maxLines: 3,
              onSaved: (v) => formData.description = v ?? '',
            ),
            const SizedBox(height: 16),

            // Rate
            TextFormField(
              initialValue: formData.rate > 0 ? formData.rate.toString() : '',
              decoration: InputDecoration(
                labelText: 'rate'.tr,
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
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
              onSaved: (v) => formData.rate = double.parse(v!),
            ),
            const SizedBox(height: 16),

            // Unit
            Obx(
              () => DropdownButtonFormField<String>(
                value: unit.value,
                items:
                    ['kg', 'liter', 'piece']
                        .map(
                          (u) => DropdownMenuItem(value: u, child: Text(u.tr)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    unit.value = value;
                    formData.unit = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'unit'.tr,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'required'.tr : null,
              ),
            ),
            const SizedBox(height: 16),

            // Available Quantity
            TextFormField(
              initialValue:
                  formData.availableQuantity > 0
                      ? formData.availableQuantity.toString()
                      : '',
              decoration: InputDecoration(
                labelText: 'available_quantity'.tr,
                border: OutlineInputBorder(),
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
              onSaved: (v) => formData.availableQuantity = double.parse(v!),
            ),
            const SizedBox(height: 16),

            // Category
            TextFormField(
              initialValue: formData.category,
              decoration: InputDecoration(
                labelText: 'category'.tr,
                border: OutlineInputBorder(),
                errorText:
                    formData.category.length > 50
                        ? 'max_50_characters'.tr
                        : null,
              ),
              maxLength: 50,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              onSaved: (v) => formData.category = v!.trim(),
            ),
            const SizedBox(height: 16),

            // Location Picker
            TextFormField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'location'.tr,
                border: const OutlineInputBorder(),
                errorText:
                    formData.location!.length > 50
                        ? 'max_50_characters'.tr
                        : null,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchLocation(locationController.text),
                ),
              ),
              maxLength: 50,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null,
              onSaved: (v) => formData.location = v!.trim(),
            ),
            const SizedBox(height: 8),

            // Latitude and Longitude
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: latitudeController,
                    decoration: InputDecoration(
                      labelText: 'latitude'.tr,
                      border: const OutlineInputBorder(),
                      errorText:
                          latitudeController.text.isNotEmpty &&
                                  double.tryParse(latitudeController.text) ==
                                      null
                              ? 'invalid_latitude'.tr
                              : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: false,
                    validator:
                        (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'required'.tr
                                : null,
                    onSaved: (v) => formData.latitude = double.parse(v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: longitudeController,
                    decoration: InputDecoration(
                      labelText: 'longitude'.tr,
                      border: const OutlineInputBorder(),
                      errorText:
                          longitudeController.text.isNotEmpty &&
                                  double.tryParse(longitudeController.text) ==
                                      null
                              ? 'invalid_longitude'.tr
                              : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: false,
                    validator:
                        (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'required'.tr
                                : null,
                    onSaved: (v) => formData.longitude = double.parse(v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: Text('use_current_location'.tr),
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () =>
                      isLoadingImage.value
                          ? Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : imageFile != null
                          ? Image.file(
                            imageFile!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                          )
                          : formData.imagePath.isNotEmpty
                          ? Image.network(
                            formData.imagePath,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                          )
                          : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image),
                          ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: Text('pick_image'.tr),
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  if (widget.product == null && imageFile == null) {
                    Get.snackbar('error'.tr, 'image_required'.tr);
                    return;
                  }
                  widget.onSubmit(formData, newImagePath);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.product == null ? 'add_product'.tr : 'update_product'.tr,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}

extension on File {
  Future<void> write(Uint8List bodyBytes) async {}
}
