import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishi_link/core/theme/app_theme.dart';
import 'package:krishi_link/exceptions/app_exception.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/device/data/device_service.dart';
import 'package:krishi_link/src/core/constants/constants.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

/// A screen for verifying OTP (One Time Password) for a given identifier.
///
/// This widget is a stateful widget that takes an [identifier] as a required parameter,
/// which is typically used to identify the user or the session for which the OTP is being verified.
class OtpVerificationScreen extends StatefulWidget {
  /// The identifier for the user or session that requires OTP verification.
  final String identifier;

  /// Creates an instance of [OtpVerificationScreen].
  ///
  /// The [identifier] parameter must not be null.
  const OtpVerificationScreen({super.key, required this.identifier});

  @override
  /// Creates an instance of [OtpVerificationScreenState].
  ///
  /// This method is overridden from the [StatefulWidget] class and is responsible
  /// for creating the mutable state for the [OtpVerificationScreen]. The state
  /// object is where the mutable state for this widget is stored.
  OtpVerificationScreenState createState() => OtpVerificationScreenState();
}

/// The state class for [OtpVerificationScreen].
///
/// This class manages the state for the OTP verification screen, including
/// handling the OTP input, timer for resending OTP, and the submission process.
class OtpVerificationScreenState extends State<OtpVerificationScreen> {
  /// The authentication controller used for verifying the OTP.
  final AuthController authController = Get.find<AuthController>();

  /// Indicates whether the OTP submission is in progress.
  final RxBool isSubmitting = false.obs;

  /// The remaining time left for resending the OTP.
  final RxInt timeLeft = 30.obs;

  /// The current OTP entered by the user.
  final RxString currentOtp = ''.obs;

  /// Timer for managing the countdown for OTP resend.
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer(); // Start the countdown timer when the state is initialized.
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the state is disposed.
    super.dispose();
  }

  /// Starts the countdown timer for resending the OTP.
  void startTimer() {
    timer?.cancel(); // Cancel any existing timer.
    timeLeft.value = 30; // Reset the timer to 30 seconds.
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft.value > 0) {
        timeLeft.value--; // Decrement the time left.
      } else {
        timer.cancel(); // Stop the timer when it reaches zero.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme.

    /// Verifies the entered OTP.
    Future<void> verifyOtp() async {
      if (currentOtp.value.length != 6) {
        PopupService.error('Invalid OTP');
        return; // Exit if the OTP is not valid.
      }

      try {
        isSubmitting(true); // Set submitting state to true.
        // final args = Get.arguments as Map<String, dynamic>;
        // final deviceId =
        // args['deviceId'] ?? (await DeviceService().getDeviceId());
        await authController.verifyOtp(widget.identifier, currentOtp.value);
        debugPrint('[OTP] Verification successful');
        // TODO: Navigate to next screen
      } on AppException {
        PopupService.error('OTP verification failed');
      } catch (e) {
        PopupService.error('OTP verification failed');
      } finally {
        isSubmitting(false); // Reset submitting state.
      }
    }

    final RxBool isResending = false.obs; // Indicates if OTP is being resent.

    /// Resends the OTP to the user.
    /// Resends the OTP (One Time Password) to the user.
    ///
    /// This method checks if an OTP is already being resent. If not, it sets the
    /// resending state to true, attempts to send a new OTP using the
    /// [authController], and displays a snackbar notification based on the
    /// success or failure of the operation. It also restarts the timer for
    /// resending the OTP.
    Future<void> resendOtp() async {
      isResending.value = false; // Reset the resending state.
      if (isResending.value) return; // Exit if already resending.
      isResending.value = true; // Set resending state to true.

      try {
        await authController.sendOtp(widget.identifier); // Send the OTP.
        PopupService.success('A new OTP has been sent to ${widget.identifier}');
        startTimer(); // Restart the timer after resending OTP.
      } catch (e) {
        PopupService.error('Failed to resend OTP. Please try again.');
      } finally {
        // isResending = false; // Uncomment if needed to reset state.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(), // Navigate back on button press.
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Enter the 6-digit OTP sent to',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.identifier,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Semantics(
                  label: 'OTP animation',
                  child: Lottie.asset(
                    AssetPaths.sending,
                    height: 200,
                    repeat: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              PinCodeTextField(
                appContext: context,
                length: 6,
                autoFocus: true,
                textStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                cursorColor: theme.colorScheme.primary,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  activeFillColor: theme.colorScheme.surface,
                  selectedFillColor: theme.colorScheme.surface,
                  inactiveFillColor: Colors.transparent,
                  activeColor: theme.colorScheme.primary,
                  selectedColor: theme.colorScheme.onError,
                  inactiveColor: Colors.grey,
                ),
                animationDuration: const Duration(milliseconds: 300),
                backgroundColor: Colors.transparent,
                enableActiveFill: true,
                onChanged: (value) => currentOtp.value = value,
                onCompleted: (value) {
                  currentOtp.value = value;
                  verifyOtp(); // Call the submit method directly.
                },
              ),

              const SizedBox(height: 24),

              /// Button to verify the OTP.
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        authController.isLoading.value || isSubmitting.value
                            ? null // Disable button if loading or submitting.
                            : () => verifyOtp(),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        authController.isLoading.value || isSubmitting.value
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            )
                            : const Text('Verify OTP'),
                  ),
                );
              }),

              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    () => Get.back(), // Navigate back to change email/phone.
                child: const Text('Change email or phone number'),
              ),
              Obx(
                () =>
                    timeLeft.value > 0
                        ? Text(
                          'Resend OTP in ${timeLeft.value}s',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),

              Obx(
                () =>
                    timeLeft.value == 0
                        ? FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 700),
                          child: TextButton(
                            onPressed: resendOtp, // Button to resend OTP.
                            child: Text(
                              'Resend OTP',
                              style: GoogleFonts.poppins(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
