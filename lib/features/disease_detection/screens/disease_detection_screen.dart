import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_link/core/lottie/popup.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/disease_detection/controller/disease_controller.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  DiseaseDetectionScreenState createState() => DiseaseDetectionScreenState();
}

class DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with SingleTickerProviderStateMixin {
  final DiseaseController controller = Get.put(DiseaseController());
  final RxString imagePath = ''.obs;
  final ScrollController scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String? extractDisease(String result) {
    if (result.contains('\n')) {
      return result.split('\n')[0].trim();
    }
    return null;
  }

  String? extractCorrection(String result) {
    if (result.contains('\n')) {
      return result.split('\n').skip(1).join('\n').trim();
    }
    return null;
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        imagePath.value = picked.path;
        PopupService.showSnackbar(
          type: PopupType.success,
          title: 'Success',
          message: 'Image selected successfully',
        );
        _animationController.forward(from: 0);
      } else {
        PopupService.info('No image selected');
      }
    } catch (e) {
      PopupService.error('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F8E9), Color(0xFFA5D6A7), Color(0xFFA5D6A7)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Crop Disease Detection',
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload or capture a crop image to diagnose diseases',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Image preview / picker
                    Obx(
                      () => FadeTransition(
                        opacity: _fadeAnimation,
                        child: GestureDetector(
                          onTap: () => pickImage(ImageSource.gallery),
                          child: Container(
                            height: constraints.maxWidth > 600 ? 320 : 240,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: themeColor.outline,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child:
                                imagePath.value.isEmpty
                                    ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Lottie.asset(
                                          leafScanning,
                                          height: 120,
                                          repeat: true,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to select an image',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    )
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.file(
                                        File(imagePath.value),
                                        height:
                                            constraints.maxWidth > 600
                                                ? 320
                                                : 240,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                ),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildImageButton(
                          icon: Icons.photo_library,
                          label: 'Gallery',
                          onPressed: () => pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 16),
                        _buildImageButton(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onPressed: () => pickImage(ImageSource.camera),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Analyze button
                    Obx(
                      () => AnimatedScale(
                        scale:
                            imagePath.value.isEmpty ||
                                    controller.isLoading.value
                                ? 0.95
                                : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed:
                              imagePath.value.isEmpty ||
                                      controller.isLoading.value
                                  ? null
                                  : () async {
                                    await controller.detectDisease(
                                      imagePath.value,
                                    );
                                    scrollToBottom();
                                    _animationController.forward(from: 0);
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(constraints.maxWidth * 0.9, 56),
                            backgroundColor: themeColor.primary,
                            foregroundColor: themeColor.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.black.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              controller.isLoading.value
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: themeColor.onPrimary,
                                    ),
                                  )
                                  : Text(
                                    'Analyze Crop',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Result / error sections
                    Obx(
                      () => FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (controller.result.value.isNotEmpty) ...[
                              Text(
                                'Diagnosis Result',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                // Use a widely-available surface color to avoid SDK version issues
                                color: themeColor.surface,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (extractDisease(
                                            controller.result.value,
                                          ) !=
                                          null) ...[
                                        _buildResultSection(
                                          icon: Icons.bug_report,
                                          title: 'Detected Disease',
                                          content:
                                              extractDisease(
                                                controller.result.value,
                                              )!,
                                          iconColor: themeColor.primary,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      if (extractCorrection(
                                                controller.result.value,
                                              ) !=
                                              null &&
                                          extractCorrection(
                                            controller.result.value,
                                          )!.isNotEmpty) ...[
                                        _buildResultSection(
                                          icon: Icons.medical_services,
                                          title: 'Recommended Action',
                                          content:
                                              extractCorrection(
                                                controller.result.value,
                                              )!,
                                          iconColor: themeColor.secondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              if ((Get.arguments is Map) &&
                                  (Get.arguments['returnResult'] == true))
                                ElevatedButton.icon(
                                  icon: Icon(
                                    Icons.save,
                                    color: themeColor.onPrimary,
                                  ),
                                  label: Text(
                                    'Use This Result',
                                    style: GoogleFonts.poppins(
                                      color: themeColor.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    final disease =
                                        extractDisease(
                                          controller.result.value,
                                        ) ??
                                        controller.result.value
                                            .split('\n')
                                            .first
                                            .trim();
                                    final correction =
                                        extractCorrection(
                                          controller.result.value,
                                        ) ??
                                        '';
                                    final lower = disease.toLowerCase();

                                    String status;
                                    if (lower.contains('healthy') ||
                                        lower.contains('no disease')) {
                                      status = 'Healthy';
                                    } else if (lower.contains('risk') ||
                                        lower.contains('early') ||
                                        lower.contains('mild')) {
                                      status = 'At Risk';
                                    } else {
                                      status = 'Infected';
                                    }

                                    Get.back(
                                      result: {
                                        'status': status,
                                        'disease':
                                            (status == 'Healthy')
                                                ? ''
                                                : disease,
                                        'careInstructions': correction,
                                        'suggestions': correction,
                                      },
                                    );
                                  },
                                ),
                            ],

                            if (controller.error.value.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                color: themeColor.errorContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: themeColor.error,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          controller.error.value,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: themeColor.onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Helpers ---------------------------------------------------------------

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: scheme.onPrimary, size: 24),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: scheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildResultSection({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: scheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
