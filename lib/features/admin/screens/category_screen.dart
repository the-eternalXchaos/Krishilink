// // lib/features/admin/screens/category_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/controller/admin_category_controller.dart';

// class CategoryScreen extends StatelessWidget {
//   const CategoryScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AdminCategoryController controller = Get.find<AdminCategoryController>();
//     final TextEditingController nameController = TextEditingController();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Categories'),
//         backgroundColor: Colors.green.shade900,
//       ),
//       body: Obx(() => controller.isLoading.value
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: nameController,
//                           decoration: const InputDecoration(labelText: 'Category Name'),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.add),
//                         onPressed: () {
//                           if (nameController.text.isNotEmpty) {
//                             controller.addCategory(nameController.text);
//                             nameController.clear();
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: controller.categories.length,
//                     itemBuilder: (context, index) {
//                       final category = controller.categories[index];
//                       return ListTile(
//                         title: Text(category.name),
//                         subtitle: Text('ID: ${category.id}'),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             )),
//     );
//   }
// }
// lib/features/admin/screens/category_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/admin/presentation/controllers/admin_category_controller.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminCategoryController controller =
        Get.find<AdminCategoryController>();
    final TextEditingController nameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Category Name',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (nameController.text.isNotEmpty) {
                                controller.addCategory(nameController.text);
                                nameController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.categories.length,
                        itemBuilder: (context, index) {
                          final category = controller.categories[index];
                          return ListTile(
                            title: Text(category.name),
                            subtitle: Text('ID: ${category.id}'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
