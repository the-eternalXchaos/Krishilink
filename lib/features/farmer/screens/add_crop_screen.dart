import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
import 'package:krishi_link/features/farmer/models/crop_model.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class AddCropScreen extends StatefulWidget {
  final CropModel? crop;

  const AddCropScreen({super.key, this.crop});

  @override
  AddCropScreenState createState() => AddCropScreenState();
}

class AddCropScreenState extends State<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _plantingDate;
  final FarmerController controller = Get.find<FarmerController>();
  var isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    if (widget.crop != null) {
      _nameController.text = widget.crop!.name;
      _notesController.text = widget.crop?.note as String;
      _plantingDate = widget.crop!.plantedAt;
    } else {
      _plantingDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
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
    final crop = CropModel(
      id: widget.crop?.id ?? '',
      name: _nameController.text.trim(),
      plantedAt: _plantingDate!,
      note: _notesController.text.trim(),
      status: widget.crop?.status ?? 'Healthy',
      suggestions: widget.crop?.suggestions ?? '',
      disease: widget.crop?.disease,
      careInstructions: widget.crop?.careInstructions,
    );

    try {
      if (widget.crop == null) {
        await controller.addCrop(
          crop,
          cropName: '',
          area: '',
          plantingDate: '',
          location: '',
          emailOrPhone: '',
        );
      } else {
        await controller.updateCrop(
          crop.id,
          crop.name,
          crop.name, //TODO  IT IS incotrrect ,CROP is not working properly
          crop.plantedAt!.toIso8601String(),
          crop.note as String,
          crop.description,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.crop == null ? 'Add Crop'.tr : 'Edit Crop'.tr,
          style: theme.textTheme.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Text(
                  'Crop Details'.tr,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Crop Name'.tr,
                    hintText: 'e.g., Tomato'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a crop name'.tr;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Planting Date'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes'.tr,
                    hintText: 'Additional details'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading.value ? null : _saveCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isLoading.value
                              ? CircularProgressIndicator(
                                color: theme.colorScheme.onPrimary,
                                strokeWidth: 2,
                              )
                              : Text(
                                widget.crop == null
                                    ? 'Add Crop'.tr
                                    : 'Update Crop'.tr,
                                style: theme.textTheme.labelLarge,
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';
// import 'package:krishi_link/features/farmer/models/crop_model.dart';

// class AddCropScreen extends StatelessWidget {
//   final CropModel? crop; // For editing
//   const AddCropScreen({super.key, this.crop});

//   @override
//   Widget build(BuildContext context) {
//     final FarmerController controller = Get.find<FarmerController>();
//     final TextEditingController nameController = TextEditingController(
//       text: crop?.name ?? '',
//     );
//     final TextEditingController descriptionController = TextEditingController(
//       text: crop?.description ?? '',
//     );

//     return Scaffold(
//       appBar: AppBar(title: Text(crop == null ? 'Add Crop' : 'Edit Crop')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(labelText: 'Crop Name'),
//             ),
//             TextField(
//               controller: descriptionController,
//               decoration: const InputDecoration(labelText: 'Description'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 final newCrop = CropModel(
//                   id:
//                       crop?.id ??
//                       DateTime.now().millisecondsSinceEpoch.toString(),
//                   name: nameController.text,
//                   description: descriptionController.text,
//                   plantedAt: DateTime.now(),
//                 );
//                 if (crop == null) {
//                   controller.addCrop(newCrop);
//                 } else {
//                   controller.updateCrop(newCrop);
//                 }
//                 Get.back();
//               },
//               child: Text(crop == null ? 'Add Crop' : 'Update Crop'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
