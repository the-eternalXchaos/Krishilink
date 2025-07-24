import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';

class TutorialDetailsScreen extends StatelessWidget {
  final TutorialModel tutorial;

  const TutorialDetailsScreen({super.key, required this.tutorial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = tutorial.createdAt ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(tutorial.title.tr, style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                tutorial.title.tr,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                tutorial.category.tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'published'.trArgs([DateFormat('MMM dd, yyyy').format(createdAt)]),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            if (tutorial.imageUrl != null)
              FadeInUp(
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text('image_placeholder'.trArgs([tutorial.imageUrl ?? ''])),
                  ),
                  // TODO: Use Image.network(tutorial.imageUrl) with error handling
                ),
              ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('overview'.tr, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        tutorial.description.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('steps'.tr, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        tutorial.content.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (tutorial.videoUrl != null) ...[
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child: Center(
                    child: Text('video_placeholder'.trArgs([tutorial.videoUrl ?? ''])),
                  ),
                  // TODO: Integrate video player (e.g., video_player package)
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
