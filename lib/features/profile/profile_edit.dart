import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/controllers/profile_controller.dart';
import 'package:krishi_link/src/core/constants/constants.dart';

class ProfileEdit extends StatelessWidget {
  const ProfileEdit({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.isLoading.value ? null : controller.updateProfile,
              child: Text(
                'save'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => Form(
            key: GlobalKey<FormState>(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                Hero(
                                  tag: 'profile_image',
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        controller.profileImage.value != null
                                            ? FileImage(
                                              controller.profileImage.value!,
                                            )
                                            : controller
                                                    .authController
                                                    .currentUser
                                                    .value!
                                                    .profileImageUrl
                                                    ?.isNotEmpty ??
                                                false
                                            ? NetworkImage(
                                              controller
                                                  .authController
                                                  .currentUser
                                                  .value!
                                                  .profileImageUrl!,
                                            )
                                            : AssetImage(
                                                  AssetPaths.defaultImage,
                                                )
                                                as ImageProvider,
                                    backgroundColor:
                                        Theme.of(context).cardColor,
                                    child:
                                        controller
                                                    .authController
                                                    .currentUser
                                                    .value!
                                                    .profileImageUrl!
                                                    .isEmpty &&
                                                controller.profileImage.value ==
                                                    null
                                            ? Icon(
                                              Icons.person,
                                              size: 60,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                            )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    onPressed: controller.pickImage,
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      shape: const CircleBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            value: controller.fullName.value,
                            onChanged:
                                (value) => controller.fullName.value = value,
                            label: 'name'.tr,
                            icon: Icons.person,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'required'.tr : null,
                          ),
                          _buildTextField(
                            value: controller.email.value,
                            onChanged:
                                (value) => controller.email.value = value,
                            label: 'email'.tr,
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'required'.tr
                                        : !RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+',
                                        ).hasMatch(value)
                                        ? 'invalid_email'.tr
                                        : null,
                          ),
                          _buildTextField(
                            value: controller.phoneNumber.value,
                            onChanged:
                                (value) => controller.phoneNumber.value = value,
                            label: 'phone'.tr,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'required'.tr : null,
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: controller.gender?.value,
                            items:
                                ['Male', 'Female', 'Rather not say']
                                    .map(
                                      (gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ),
                                    )
                                    .toList(),
                            onChanged: controller.setGender,
                            decoration: InputDecoration(
                              labelText: 'gender'.tr,
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surface.withAlpha(30),
                            ),
                            validator:
                                (value) => value == null ? 'required'.tr : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (controller.isLoading.value)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String value,
    required ValueChanged<String> onChanged,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
