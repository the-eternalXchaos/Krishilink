// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:krishi_link/core/theme/app_theme.dart';

// class TutorialsScreen extends StatelessWidget {
//   const TutorialsScreen({super.key});

//   // Mocked tutorial data (replace with API call)
//   final List<Map<String, dynamic>> tutorials = [
//     {
//       'id': '1',
//       'title': 'How to Prevent Early Blight in Tomatoes',
//       'description':
//           'Learn effective methods to protect your tomato crops from early blight.',
//       'category': 'Disease Prevention',
//     },
//     {
//       'id': '2',
//       'title': 'Optimal Watering Techniques for Paddy',
//       'description':
//           'Master the art of watering paddy crops for maximum yield.',
//       'category': 'Crop Care',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('tutorials'.tr, style: theme.textTheme.titleLarge),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body:
//           tutorials.isEmpty
//               ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.book, size: 80, color: Colors.grey.shade400),
//                     const SizedBox(height: 16),
//                     Text(
//                       'no_tutorials_available'.tr,
//                       style: theme.textTheme.bodyLarge,
//                     ),
//                   ],
//                 ),
//               )
//               : ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: tutorials.length,
//                 itemBuilder: (context, index) {
//                   final tutorial = tutorials[index];
//                   return FadeInUp(
//                     delay: Duration(milliseconds: 100 * index),
//                     child: Card(
//                       elevation: 2,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundColor: theme.colorScheme.primaryContainer,
//                           child: Icon(
//                             Icons.book,
//                             color: theme.colorScheme.primary,
//                           ),
//                         ),
//                         title: Text(
//                           tutorial['title'].tr,
//                           style: theme.textTheme.titleMedium,
//                         ),
//                         subtitle: Text(
//                           tutorial['category'].tr,
//                           style: theme.textTheme.bodyMedium,
//                         ),
//                         onTap: () {
//                           Get.snackbar(
//                             'Tutorial'.tr,
//                             tutorial['description'].tr,
//                             backgroundColor: theme.colorScheme.primary,
//                             colorText: theme.colorScheme.onPrimary,
//                           );
//                           // TODO: Navigate to tutorial details screen
//                           // Get.toNamed('/tutorial-details', arguments: tutorial);
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';

class TutorialsScreen extends StatelessWidget {
  TutorialsScreen({super.key});

  // Mocked tutorial data (replace with API call)
  final List<TutorialModel> tutorials = [
    TutorialModel(
      id: '1',
      title: 'How to Prevent Early Blight in Tomatoes',
      category: 'Disease Prevention',
      description:
          'Learn effective methods to protect your tomato crops from early blight.',
      content:
          '1. Use resistant varieties.\n2. Apply fungicides early.\n3. Remove infected leaves.\n4. Ensure proper spacing.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      imageUrl: earlyBlightImage,
      
    ),
    TutorialModel(
      id: '2',
      title: 'Optimal Watering Techniques for Paddy',
      category: 'Crop Care',
      description: 'Master the art of watering paddy crops for maximum yield.',
      content:
          '1. Maintain 2-5 cm water depth.\n2. Use intermittent irrigation.\n3. Monitor soil moisture.\n4. Avoid water stress during flowering.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      videoUrl: 'https://example.com/paddy.mp4',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tutorials'.tr, style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Get.back(),
        ),
      ),
      body:
          tutorials.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No tutorials available'.tr,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final tutorial = tutorials[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.book,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          tutorial.title.tr,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          tutorial.category.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () {
                          Get.toNamed('/tutorial-details', arguments: tutorial);
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// Obx(() => controller.tutorials.isEmpty ? ... : ListView.builder(...)),
// pai integration for th eturorials
//  final response = await http.get(Uri.parse(ApiConstants.getTutorialsEndpoint));
// tutorials.value = (jsonDecode(response.body) as List).map((e) => TutorialModel.fromJson(e)).toList();
