// lib/features/farmer/screens/add_crop_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/constants/app_spacing.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/widgets/app_widgets.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';

class AddCropScreen extends StatefulWidget {
  final CropModel? crop;

  const AddCropScreen({super.key, this.crop});

  @override
  AddCropScreenState createState() => AddCropScreenState();
}

class AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _plantingDate;
  final FarmerController controller = Get.find<FarmerController>();
  var isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    if (widget.crop != null) {
      _nameController.text = widget.crop!.name;
      _notesController.text = widget.crop?.note ?? '';
      _areaController.text =
          widget.crop?.description ?? ''; // Using description as area for now
      _locationController.text = widget.crop?.description ?? ''; // Placeholder
      _descriptionController.text = widget.crop?.description ?? '';
      _plantingDate = widget.crop!.plantedAt;
    } else {
      _plantingDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _emailOrPhoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _plantingDate) {
      setState(() {
        _plantingDate = picked;
      });
    }
  }

  void _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;

    isLoading(true);
    try {
      if (widget.crop == null) {
        await controller.addCrop(
          CropModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text.trim(),
            plantedAt: _plantingDate!,
            note: _notesController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
            status: 'Healthy',
            suggestions: '',
            disease: null,
            careInstructions: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          cropName: _nameController.text.trim(),
          area: _areaController.text.trim(),
          plantingDate: _plantingDate!.toIso8601String(),
          location: _locationController.text.trim(),
          emailOrPhone: _emailOrPhoneController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
        );
      } else {
        await controller.updateCrop(
          widget.crop!.id,
          _nameController.text.trim(),
          _areaController.text.trim().isEmpty
              ? null
              : _areaController.text.trim(),
          _plantingDate!.toIso8601String(),
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }
      Get.back();
    } catch (e) {
      PopupService.error('Failed to save crop: $e');
    } finally {
      isLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.crop == null ? 'Add Crop'.tr : 'Edit Crop'.tr,
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: AppWidgets.card(
            colorScheme: colorScheme,
            title: 'Crop Details'.tr,
            icon: Icons.grass,
            iconColor: colorScheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  child: AppWidgets.textField(
                    controller: _nameController,
                    label: 'Crop Name'.tr,
                    icon: Icons.tag,
                    colorScheme: colorScheme,
                    onChanged: null, // Not needed for form input
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a crop name'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: AppWidgets.textField(
                    controller: _areaController,
                    label: 'Area (e.g., 100 sqm)'.tr,
                    icon: Icons.square_foot,
                    colorScheme: colorScheme,
                    onChanged: null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the area'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: AppWidgets.textField(
                    controller: _locationController,
                    label: 'Location'.tr,
                    icon: Icons.location_on,
                    colorScheme: colorScheme,
                    onChanged: null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please_enter_the_location'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: AppWidgets.textField(
                    controller: _emailOrPhoneController,
                    label: 'Email or Phone'.tr,
                    icon: Icons.contact_mail,
                    colorScheme: colorScheme,
                    onChanged: null,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter email or phone'.tr;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Planting Date'.tr,
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: Text(
                        _plantingDate == null
                            ? 'Select Date'.tr
                            : DateFormat('MMM dd, yyyy').format(_plantingDate!),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: AppWidgets.textField(
                    controller: _notesController,
                    label: 'Notes'.tr,
                    icon: Icons.note,
                    colorScheme: colorScheme,
                    onChanged: null,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: AppWidgets.textField(
                    controller: _descriptionController,
                    label: 'Description'.tr,
                    icon: Icons.description,
                    colorScheme: colorScheme,
                    onChanged: null,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Obx(
                    () => AppWidgets.button(
                      text:
                          widget.crop == null
                              ? 'Add Crop'.tr
                              : 'Update Crop'.tr,
                      onPressed: isLoading.value ? null : _saveCrop,
                      loading: isLoading.value,
                      icon: widget.crop == null ? Icons.add : Icons.save,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
