import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/farmer/models/tutorial_model.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:krishi_link/widgets/safe_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class TutorialsScreen extends StatelessWidget {
  TutorialsScreen({super.key});

  final List<TutorialModel> tutorials = [
    TutorialModel(
      id: '1',
      title: 'टमाटरमा प्रारम्भिक ब्लाइट रोक्ने तरिका',
      category: 'रोग प्रतिरोध / Disease Prevention',
      description:
          'तपाईंको टमाटर बालीलाई प्रारम्भिक ब्लाइटबाट सुरक्षित राख्ने प्रभावकारी विधिहरू सिक्नुहोस्।',
      content:
          '1. प्रतिरोधी किसिम प्रयोग गर्नुहोस्।\n2. छिटै फङ्गिसाइड लगाउनुहोस्।\n3. संक्रमित पातहरू हटाउनुहोस्।\n4. उचित दूरीमा रोपण गर्नुहोस्।',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      imageUrl: 'lib/src/core/assets/tutorials_images/tomato_early_blight.jpg',
      videoUrl: 'https://www.youtube.com/watch?v=nCM6CMIkDdM',
    ),
    TutorialModel(
      id: '2',
      title: 'धानका लागि उत्तम सिँचाइ प्रविधिहरू',
      category: 'बाली हेरचाह / Crop Care',
      description:
          'उच्च उत्पादनका लागि धान बालीमा सिँचाइको कला मास्टर गर्नुहोस्।',
      content:
          '1. पानीको गहिराइ २-५ से.मि. राख्नुहोस्।\n2. अबरुद्ध सिँचाइ प्रयोग गर्नुहोस्।\n3. माटोको नमी अनुगमन गर्नुहोस्।\n4. फूलिने बेला पानीको कमी हुन नदिनुहोस्।',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      imageUrl: AssetPaths.paddyIrrigation,

      videoUrl: 'https://www.youtube.com/watch?v=6nIB9eU2Uso',
    ),
    TutorialModel(
      id: '3',
      title: 'तरकारीका लागि माटो तयार गर्ने आधारभूत तरिका',
      category: 'माटो एवं पोषक तत्वहरू / Soil & Nutrients',
      description: 'स्वस्थ, राम्ररी ड्रेनेज भएको बेड तयार गर्ने सरल कदमहरू।',
      content:
          '1. किरानीहरु पन्छाउनुहोस्।\n2. कम्पोस्ट थप्नुहोस्।\n3. माथिल्लो माटो २०-२५ से.मि. गहिराइमा चिसो पार्नुहोस्।\n4. समतल गर्नुहोस् र मल्च लगाउनुहोस्।',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      imageUrl: AssetPaths.soilPreparation,

      videoUrl: 'https://www.youtube.com/shorts/2q8I9wkDhi0',
    ),
    TutorialModel(
      id: '4',
      title: 'कीट-निरीक्षण जाँचसूची',
      category: 'कीट व्यवस्थापन / Pest Management',
      description:
          'हप्ताअघि कीटहरु चाँडै पहिचान गर्न र कार्य गर्नको लागि जाँचसूची।',
      content:
          '1. पातको तल छेउ हेर्नुहोस्।\n2. ट्र्यापहरु जाँच्नुहोस्।\n3. असामान्य दागहरु नोट गर्नुहोस्।\n4. फोटो खिचेर लग राख्नुहोस्।',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      imageUrl: AssetPaths.pestScouting,
      videoUrl: 'https://www.youtube.com/shorts/1IDPl_510-Q',
    ),
    TutorialModel(
      id: '5',
      title: 'पातिला हरियो तरकारीको पोस्ट-हर्वेस्ट ह्यान्डलिङ',
      category: 'उत्पादनपछिको व्यवस्थापन / Harvesting',
      description:
          'फिल्डदेखि बजारसम्म तपाईंका हरियो तरकारी ताजा रहुन् भन्ने उपाय।',
      content:
          '1. बिहानै सकिने बेला हर्पेस्ट गर्नुहोस्।\n2. तुरुन्त छायामा राख्नुहोस्।\n3. धुने र स्पिन-ड्राई गर्नुहोस्।\n4. सरसफाइ भएको प्याकिङमा भेन्टिलेसनसहित राख्नुहोस्।',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      imageUrl: AssetPaths.postHarvest,
      videoUrl: 'https://youtube.com/shorts/eMucKazry3M?si=94JSlKgprwD8XURG',
    ),
    TutorialModel(
      id: '6',
      title: 'ओर्गानिक मल १०१',
      category: 'माटो एवं पोषक तत्वहरू / Soil & Nutrients',
      description:
          'कम्पोस्ट, भर्मी–कम्पोस्ट, र गोबर—कहिले र कसरी प्रयोग गर्ने।',
      content:
          '1. पहिलो माटो परीक्षण गर्नुहोस्।\n2. कम्पोस्ट समान रूपमा लगाउनुहोस्।\n3. अत्यधिक मल नदिने सुझाव।\n4. बालीको प्रतिक्रियालाई अनुगमन गर्नुहोस्।',
      createdAt: DateTime.now(),
      imageUrl: AssetPaths.organicFertilizer,
      videoUrl: 'https://www.youtube.com/watch?v=ZHLOR3JO4Yk',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ट्युटोरियल्स'.tr, style: theme.textTheme.titleLarge),
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
                      'ट्युटोरियल उपलब्ध छैन'.tr,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tutorials.length,
                itemBuilder: (context, index) {
                  final t = tutorials[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 90 * index),
                    child: _TutorialCard(
                      tutorial: t,
                      onOpenDetails:
                          () => Get.toNamed('/tutorial-details', arguments: t),
                      onOpenVideo: () => _openUrl(context, t.videoUrl),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _openUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) {
      Get.snackbar(
        'भिडियो',
        'चलाउनको लागि YouTube लिंक कोडमा थप्नुहोस्।',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.surface,
      );
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('भिडियो', 'लिङ्क खोल्न सकेन।');
    }
  }
}

class _TutorialCard extends StatelessWidget {
  final TutorialModel tutorial;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenVideo;
  const _TutorialCard({
    required this.tutorial,
    required this.onOpenDetails,
    required this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasNetworkImage =
        (tutorial.imageUrl?.startsWith('http') ?? false) &&
        (tutorial.imageUrl?.isNotEmpty ?? false);
    final hasAssetImage =
        (tutorial.imageUrl?.isNotEmpty ?? false) && !hasNetworkImage;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child:
                  hasNetworkImage
                      ? SafeNetworkImage(
                        imageUrl: tutorial.imageUrl!,
                        fit: BoxFit.cover,
                      )
                      : hasAssetImage
                      ? Image.asset(
                        tutorial.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                Image.asset(AssetPaths.plantPlaceholder),
                      )
                      : Container(
                        color: cs.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutorial.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(label: tutorial.category),
                    const SizedBox(width: 8),
                    if (tutorial.createdAt != null)
                      _Chip(
                        label:
                            '${tutorial.createdAt!.year}-${tutorial.createdAt!.month.toString().padLeft(2, '0')}-${tutorial.createdAt!.day.toString().padLeft(2, '0')}',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(tutorial.description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('ट्युटोरियल पढ्नुहोस्'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (tutorial.videoUrl != null &&
                                tutorial.videoUrl!.trim().isNotEmpty)
                            ? onOpenVideo
                            : null,
                    icon: const Icon(Icons.ondemand_video),
                    label: Text(
                      (tutorial.videoUrl != null &&
                              tutorial.videoUrl!.trim().isNotEmpty)
                          ? 'भिडियो हेर्नुहोस्'
                          : 'YouTube लिंक थप्नुहोस्',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
