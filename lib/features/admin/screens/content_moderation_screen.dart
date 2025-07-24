// lib/features/admin/screens/content_moderation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/admin/controllers/admin_moderation_controller.dart';

class ContentModerationScreen extends StatelessWidget {
  const ContentModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminModerationController controller = Get.find<AdminModerationController>();
    final TextEditingController wordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: wordController,
                          decoration: const InputDecoration(labelText: 'Offensive Word'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (wordController.text.isNotEmpty) {
                            controller.addOffensiveWord(wordController.text);
                            wordController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.offensiveWords.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(controller.offensiveWords[index]),
                      );
                    },
                  ),
                ),
              ],
            )),
    );
  }
}