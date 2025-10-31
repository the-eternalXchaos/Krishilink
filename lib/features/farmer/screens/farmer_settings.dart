// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:krishi_link/core/theme/app_theme.dart';
// import 'package:krishi_link/src/core/constants/api_constants.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'package:krishi_link/core/controllers/language_controller.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';

// class FarmerSettings extends StatefulWidget {
//   const FarmerSettings({super.key});

//   @override
//   FarmerSettingsState createState() => FarmerSettingsState();
// }

// class FarmerSettingsState extends State<FarmerSettings> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _contactController = TextEditingController();
//   var isLoading = false.obs;
//   final _authController = Get.find<AuthController>();
//   final _languageController = Get.find<LanguageController>();

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserProfile();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _contactController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchUserProfile() async {
//     try {
//       final response = await http.get(
//         Uri.parse(ApiConstants.getUserDetailsEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${_authController.userData?.token}',
//         },
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         _nameController.text = data['name'] ?? '';
//         _contactController.text = data['contact'] ?? '';
//       } else {
//         throw 'Failed to fetch profile: ${response.statusCode}';
//       }
//     } catch (e) {
//       Get.snackbar('Error'.tr, 'Failed to load profile: $e'.tr);
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;

//     isLoading(true);
//     try {
//       final response = await http.post(
//         Uri.parse(ApiConstants.updateProfileEndpoint),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer ${_authController.userData?.token}',
//         },
//         body: jsonEncode({
//           'name': _nameController.text.trim(),
//           'contact': _contactController.text.trim(),
//         }),
//       );
//       if (response.statusCode == 200) {
//         Get.snackbar('Success'.tr, 'Profile updated successfully'.tr);
//       } else {
//         throw 'Failed to update profile: ${response.statusCode}';
//       }
//     } catch (e) {
//       Get.snackbar('Error'.tr, 'Failed to update profile: $e'.tr);
//     } finally {
//       isLoading(false);
//     }
//   }

//   void _changeLanguage(String langCode) {
//     Get.updateLocale(Locale(langCode));
//     selectedLanguage = langCode;
//     setState(() {});
//   }

//   void _logout() {
//     Get.defaultDialog(
//       title: 'Logout'.tr,
//       middleText: 'Are you sure you want to logout?'.tr,
//       textConfirm: 'Yes'.tr,
//       textCancel: 'No'.tr,
//       confirmTextColor: Colors.white,
//       onConfirm: () {
//         _authController.logout(); // Assumed logout clears token
//         Get.offAllNamed('/login');
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Settings'.tr, style: theme.textTheme.titleLarge),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FadeInDown(
//               child: Text(
//                 'Profile Settings'.tr,
//                 style: theme.textTheme.headlineMedium,
//               ),
//             ),
//             const SizedBox(height: 16),
//             FadeInUp(
//               child: Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             labelText: 'Name'.tr,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           validator:
//                               (value) =>
//                                   value!.isEmpty
//                                       ? 'Please enter your name'.tr
//                                       : null,
//                         ),
//                         const SizedBox(height: 12),
//                         TextFormField(
//                           controller: _contactController,
//                           decoration: InputDecoration(
//                             labelText: 'Contact Number'.tr,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           keyboardType: TextInputType.phone,
//                           validator:
//                               (value) =>
//                                   value!.isEmpty
//                                       ? 'Please enter your contact'.tr
//                                       : null,
//                         ),
//                         const SizedBox(height: 16),
//                         Obx(
//                           () => SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed:
//                                   isLoading.value ? null : _updateProfile,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: theme.colorScheme.primary,
//                                 foregroundColor: theme.colorScheme.onPrimary,
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               child:
//                                   isLoading.value
//                                       ? CircularProgressIndicator(
//                                         color: theme.colorScheme.onPrimary,
//                                         strokeWidth: 2,
//                                       )
//                                       : Text(
//                                         'Update Profile'.tr,
//                                         style: theme.textTheme.labelLarge,
//                                       ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             FadeInUp(
//               delay: const Duration(milliseconds: 100),
//               child: Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Language'.tr, style: theme.textTheme.titleLarge),
//                       const SizedBox(height: 12),
//                       DropdownButtonFormField<String>(
//                         value: selectedLanguage,
//                         decoration: InputDecoration(
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         items: [
//                           DropdownMenuItem(
//                             value: 'en',
//                             child: Text('English'.tr),
//                           ),
//                           DropdownMenuItem(
//                             value: 'ne',
//                             child: Text('Nepali'.tr),
//                           ),
//                         ],
//                         onChanged: (value) => _changeLanguage(value!),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             FadeInUp(
//               delay: const Duration(milliseconds: 200),
//               child: Card(
//                 elevation: 3,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ListTile(
//                   leading: Icon(Icons.logout, color: theme.colorScheme.error),
//                   title: Text('Logout'.tr, style: theme.textTheme.titleMedium),
//                   onTap: _logout,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
