import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/disease_detection/controller/disease_controller.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  _DiseaseDetectionScreenState createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
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
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    // Start animation
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        imagePath.value = picked.path;
        PopupService.success('Image selected successfully');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4EEE5), Color(0xFF77B07A)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Disease Detection',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyze your crop images',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          height: constraints.maxWidth > 600 ? 300 : 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child:
                              imagePath.value.isEmpty
                                  ? Center(
                                    child: Lottie.asset(
                                      leafScanning, // Add a Lottie animation in assets
                                      // height: 500, .. or user auto
                                      repeat: true,
                                    ),
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(imagePath.value),
                                      height:
                                          constraints.maxWidth > 600
                                              ? 300
                                              : 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Gallery',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => pickImage(ImageSource.gallery),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Camera',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => AnimatedScale(
                        scale:
                            imagePath.value.isEmpty ||
                                    controller.isLoading.value
                                ? 0.95
                                : 1.0,
                        duration: const Duration(milliseconds: 200),
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
                            minimumSize: Size(constraints.maxWidth * 0.8, 48),
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child:
                              controller.isLoading.value
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    'Analyze',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(
                      () => FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (controller.result.value.isNotEmpty) ...[
                              Text(
                                'Result',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.green[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (extractDisease(
                                            controller.result.value,
                                          ) !=
                                          null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.bug_report,
                                              color: Colors.green[800],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                extractDisease(
                                                  controller.result.value,
                                                )!,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[900],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      if (extractCorrection(
                                                controller.result.value,
                                              ) !=
                                              null &&
                                          extractCorrection(
                                            controller.result.value,
                                          )!.isNotEmpty) ...[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.medical_services,
                                              color: Colors.orange[800],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                extractCorrection(
                                                  controller.result.value,
                                                )!,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (controller.error.value.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.red[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.error, color: Colors.red[800]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          controller.error.value,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.red[900],
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
