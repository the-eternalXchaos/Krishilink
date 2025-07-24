import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krishi_link/core/utils/constants.dart';
import 'package:krishi_link/features/auth/controller/register_controller.dart';
import 'package:krishi_link/features/auth/screens/login_screen.dart';
import 'package:krishi_link/features/auth/widgets/social_iconbutton.dart';
import 'package:lottie/lottie.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRole;
  bool _isLoading = false;
  bool _agreed = false;

  static const _allowedDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'icloud.com',
    'endibit.com',
  ];

  bool _isValidDomain(String email) {
    try {
      final domain = email.split('@').last.toLowerCase();
      return _allowedDomains.contains(domain);
    } catch (_) {
      return false;
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a role")));
      return;
    }

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the terms")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare your controller (or create it if not done yet)
      final registerController = Get.put(RegisterController());

      // Fill controller fields from your form inputs
      registerController.fullNameController.text = _nameController.text;
      registerController.emailOrPhoneController.text =
          _emailOrPhoneController.text;
      registerController.passwordController.text = _passwordController.text;
      registerController.confirmPasswordController.text =
          _confirmPasswordController.text;

      registerController.role.value = _selectedRole!;

      // Call register API via controller method
      await registerController.register();

      // If success, navigate to login or home
      if (registerController.errorMessage.isEmpty) {
        // Example navigation after successful registration:
        Get.offNamed('/login');
      } else {
        PopupService.error(registerController.errorMessage.value.toString());
      }
    } catch (e) {
      PopupService.error('registration_failed'.tr);
      debugPrint("--Error-- $e ");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSocialRegister(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign up with $provider not yet implemented.')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Creates an [InputDecoration] with a specified label, icon, and theme.
  ///
  /// This function returns a customized [InputDecoration] that includes a prefix icon,
  /// a label text, and a filled background color. The border of the input field is
  /// styled with rounded corners.
  ///
  /// Parameters:
  /// - [label]: The text to display as the label for the input field.
  /// - [icon]: The icon to display as a prefix in the input field.
  /// - [theme]: The current theme data, which can be used for further customization (not used in this implementation).
  ///
  /// Returns:
  /// An [InputDecoration] object configured with the provided parameters.
  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ThemeData theme,
  ) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  InputDecoration _passwordInput(
    String label,
    ThemeData theme, {
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.lock),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSocialButton(String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(iconPath, height: 36, width: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, size: 70, color: Colors.green[700]),
                        const SizedBox(height: 8),
                        Text(
                          'Krishi Link',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create Your Account',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            'Full Name',
                            Icons.person,
                            theme,
                          ),
                          style: GoogleFonts.poppins(fontSize: 18),
                          validator:
                              (value) =>
                                  value == null || value.trim().length < 3
                                      ? 'Enter at least 3 characters'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailOrPhoneController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            'Email or Phone',
                            Icons.alternate_email,
                            theme,
                          ),
                          style: GoogleFonts.poppins(fontSize: 18),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email or phone number';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            final phoneRegex = RegExp(r'^[9876]\d{9}$');

                            if (emailRegex.hasMatch(value)) {
                              if (!_isValidDomain(value)) {
                                return 'Allowed domains: ${_allowedDomains.join(', ')}';
                              }
                              return null;
                            } else if (phoneRegex.hasMatch(value)) {
                              return null;
                            } else {
                              return 'Enter valid email or phone number';
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _passwordInput(
                            'Password',
                            theme,
                            obscure: _obscurePassword,
                            toggle: _togglePasswordVisibility,
                          ),
                          style: GoogleFonts.poppins(fontSize: 18),
                          validator:
                              (value) =>
                                  value == null || value.length < 8
                                      ? 'Password must be at least 8 characters including special character and uppercase '
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _passwordInput(
                            'Confirm Password',
                            theme,
                            obscure: _obscureConfirmPassword,
                            toggle: _toggleConfirmPasswordVisibility,
                          ),
                          style: GoogleFonts.poppins(fontSize: 18),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select Your Role',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ToggleButtons(
                          isSelected: [
                            _selectedRole == 'farmer',
                            _selectedRole == 'buyer',
                          ],
                          onPressed: (index) {
                            setState(() {
                              _selectedRole = index == 0 ? 'farmer' : 'buyer';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[600],
                          selectedColor: Colors.white,
                          fillColor: Colors.green[700],
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                'Farmer',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                'Buyer',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isLoading ? null : _register,
                            child:
                                _isLoading
                                    ? CircularProgressIndicator()
                                    : Text(
                                      'Create Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreed,
                              onChanged: (v) => setState(() => _agreed = v!),
                            ),
                            Expanded(
                              child: Text(
                                "I agree to the Terms and Privacy Policy",
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'Or continue with',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              googleLogoPath,
                              () => _handleSocialRegister('Google'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              facebookLogoPath,
                              () => _handleSocialRegister('Facebook'),
                            ),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                              appleLogoPath,
                              () => _handleSocialRegister('Apple'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => Get.to(() => const LoginScreen()),
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
