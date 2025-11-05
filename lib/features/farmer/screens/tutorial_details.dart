import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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
                'published'.trArgs([
                  DateFormat('MMM dd, yyyy').format(createdAt),
                ]),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            if ((tutorial.imageUrl ?? '').trim().isNotEmpty)
              FadeInUp(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child:
                        (tutorial.imageUrl!.startsWith('http'))
                            ? SafeNetworkImage(
                              imageUrl: tutorial.imageUrl!,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              tutorial.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Image.asset(AssetPaths.plantPlaceholder),
                            ),
                  ),
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
            if ((tutorial.videoUrl ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.ondemand_video, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'भिडियो हेर्नुहोस्'.tr,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: Text('Open'.tr),
                          onPressed: () async {
                            final raw = tutorial.videoUrl!.trim();
                            final uri = Uri.tryParse(raw);
                            if (uri == null) return;
                            final ok = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!ok) {
                              Get.snackbar('भिडियो', 'लिङ्क खोल्न सकेन।');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
