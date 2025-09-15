// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/features/auth/controller/register_controller.dart';
// import 'package:krishi_link/features/auth/screens/login_screen.dart';
// import 'package:krishi_link/features/auth/widgets/social_iconbutton.dart';
// import 'package:lottie/lottie.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailOrPhoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   String? _selectedRole;
//   bool _isLoading = false;
//   bool _agreed = false;

//   static const _allowedDomains = [
//     'gmail.com',
//     'yahoo.com',
//     'outlook.com',
//     'hotmail.com',
//     'icloud.com',
//     'endibit.com',
//   ];

//   bool _isValidDomain(String email) {
//     try {
//       final domain = email.split('@').last.toLowerCase();
//       return _allowedDomains.contains(domain);
//     } catch (_) {
//       return false;
//     }
//   }

//   void _togglePasswordVisibility() {
//     setState(() => _obscurePassword = !_obscurePassword);
//   }

//   void _toggleConfirmPasswordVisibility() {
//     setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
//   }

//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedRole == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please select a role")));
//       return;
//     }

//     if (!_agreed) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("You must agree to the terms")),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Prepare your controller (or create it if not done yet)
//       final registerController = Get.put(RegisterController());

//       // Fill controller fields from your form inputs
//       registerController.fullNameController.text = _nameController.text;
//       registerController.emailOrPhoneController.text =
//           _emailOrPhoneController.text;
//       registerController.passwordController.text = _passwordController.text;
//       registerController.confirmPasswordController.text =
//           _confirmPasswordController.text;

//       registerController.role.value = _selectedRole!;

//       // Call register API via controller method
//       await registerController.register();

//       // If success, navigate to login or home
//       if (registerController.errorMessage.isEmpty) {
//         // Example navigation after successful registration:
//         Get.offNamed('/login');
//       } else {
//         PopupService.error(registerController.errorMessage.value.toString());
//       }
//     } catch (e) {
//       PopupService.error('registration_failed'.tr);
//       debugPrint("--Error-- $e ");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _handleSocialRegister(String provider) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Sign up with $provider not yet implemented.')),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailOrPhoneController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   /// Creates an [InputDecoration] with a specified label, icon, and theme.
//   ///
//   /// This function returns a customized [InputDecoration] that includes a prefix icon,
//   /// a label text, and a filled background color. The border of the input field is
//   /// styled with rounded corners.
//   ///
//   /// Parameters:
//   /// - [label]: The text to display as the label for the input field.
//   /// - [icon]: The icon to display as a prefix in the input field.
//   /// - [theme]: The current theme data, which can be used for further customization (not used in this implementation).
//   ///
//   /// Returns:
//   /// An [InputDecoration] object configured with the provided parameters.
//   InputDecoration _inputDecoration(
//     String label,
//     IconData icon,
//     ThemeData theme,
//   ) {
//     return InputDecoration(
//       prefixIcon: Icon(icon),
//       labelText: label,
//       filled: true,
//       fillColor: Theme.of(context).colorScheme.surface,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     );
//   }

//   InputDecoration _passwordInput(
//     String label,
//     ThemeData theme, {
//     required bool obscure,
//     required VoidCallback toggle,
//   }) {
//     return InputDecoration(
//       prefixIcon: const Icon(Icons.lock),
//       suffixIcon: IconButton(
//         icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
//         onPressed: toggle,
//       ),
//       labelText: label,
//       filled: true,
//       fillColor: Theme.of(context).colorScheme.surface,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     );
//   }

//   Widget _buildSocialButton(String iconPath, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withAlpha(76),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Image.asset(iconPath, height: 36, width: 36),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFE4EEE5), Color(0xFF77B07A)],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(maxWidth: 500),
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 16,
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.eco, size: 70, color: Colors.green[700]),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Krishi Link',
//                           style: GoogleFonts.poppins(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green[900],
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Create Your Account',
//                           style: GoogleFonts.poppins(
//                             fontSize: 18,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: _inputDecoration(
//                             'Full Name',
//                             Icons.person,
//                             theme,
//                           ),
//                           style: GoogleFonts.poppins(fontSize: 18),
//                           validator:
//                               (value) =>
//                                   value == null || value.trim().length < 3
//                                       ? 'Enter at least 3 characters'
//                                       : null,
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _emailOrPhoneController,
//                           keyboardType: TextInputType.emailAddress,
//                           decoration: _inputDecoration(
//                             'Email or Phone',
//                             Icons.alternate_email,
//                             theme,
//                           ),
//                           style: GoogleFonts.poppins(fontSize: 18),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter an email or phone number';
//                             }
//                             final emailRegex = RegExp(
//                               r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                             );
//                             final phoneRegex = RegExp(r'^[9876]\d{9}$');

//                             if (emailRegex.hasMatch(value)) {
//                               if (!_isValidDomain(value)) {
//                                 return 'Allowed domains: ${_allowedDomains.join(', ')}';
//                               }
//                               return null;
//                             } else if (phoneRegex.hasMatch(value)) {
//                               return null;
//                             } else {
//                               return 'Enter valid email or phone number';
//                             }
//                           },
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _passwordController,
//                           obscureText: _obscurePassword,
//                           decoration: _passwordInput(
//                             'Password',
//                             theme,
//                             obscure: _obscurePassword,
//                             toggle: _togglePasswordVisibility,
//                           ),
//                           style: GoogleFonts.poppins(fontSize: 18),
//                           validator:
//                               (value) =>
//                                   value == null || value.length < 8
//                                       ? 'Password must be at least 8 characters including special character and uppercase '
//                                       : null,
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: _confirmPasswordController,
//                           obscureText: _obscureConfirmPassword,
//                           decoration: _passwordInput(
//                             'Confirm Password',
//                             theme,
//                             obscure: _obscureConfirmPassword,
//                             toggle: _toggleConfirmPasswordVisibility,
//                           ),
//                           style: GoogleFonts.poppins(fontSize: 18),
//                           validator: (value) {
//                             if (value != _passwordController.text) {
//                               return 'Passwords do not match';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 24),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'Select Your Role',
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         ToggleButtons(
//                           isSelected: [
//                             _selectedRole == 'farmer',
//                             _selectedRole == 'buyer',
//                           ],
//                           onPressed: (index) {
//                             setState(() {
//                               _selectedRole = index == 0 ? 'farmer' : 'buyer';
//                             });
//                           },
//                           borderRadius: BorderRadius.circular(12),
//                           color: Colors.grey[600],
//                           selectedColor: Colors.white,
//                           fillColor: Colors.green[700],
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                               child: Text(
//                                 'Farmer',
//                                 style: GoogleFonts.poppins(fontSize: 16),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                               child: Text(
//                                 'Buyer',
//                                 style: GoogleFonts.poppins(fontSize: 16),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 28),
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green[700],
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 4,
//                             ),
//                             onPressed: _isLoading ? null : _register,
//                             child:
//                                 _isLoading
//                                     ? CircularProgressIndicator()
//                                     : Text(
//                                       'Create Account',
//                                       style: GoogleFonts.poppins(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         Row(
//                           children: [
//                             Checkbox(
//                               value: _agreed,
//                               onChanged: (v) => setState(() => _agreed = v!),
//                             ),
//                             Expanded(
//                               child: Text(
//                                 "I agree to the Terms and Privacy Policy",
//                                 style: GoogleFonts.poppins(fontSize: 14),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           children: [
//                             Expanded(child: Divider(color: Colors.grey[400])),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                               ),
//                               child: Text(
//                                 'Or continue with',
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.grey[700],
//                                 ),
//                               ),
//                             ),
//                             Expanded(child: Divider(color: Colors.grey[400])),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildSocialButton(
//                               googleLogoPath,
//                               () => _handleSocialRegister('Google'),
//                             ),
//                             const SizedBox(width: 16),
//                             _buildSocialButton(
//                               facebookLogoPath,
//                               () => _handleSocialRegister('Facebook'),
//                             ),
//                             const SizedBox(width: 16),
//                             _buildSocialButton(
//                               appleLogoPath,
//                               () => _handleSocialRegister('Apple'),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 24),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               'Already have an account?',
//                               style: GoogleFonts.poppins(
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                             TextButton(
//                               onPressed:
//                                   () => Get.to(() => const LoginScreen()),
//                               child: Text(
//                                 'Login',
//                                 style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.green[800],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

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
      _showSnackBar("Please select a role", isError: true);
      return;
    }

    if (!_agreed) {
      _showSnackBar("You must agree to the terms", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registerController = Get.put(RegisterController());

      registerController.fullNameController.text = _nameController.text;
      registerController.emailOrPhoneController.text =
          _emailOrPhoneController.text;
      registerController.passwordController.text = _passwordController.text;
      registerController.confirmPasswordController.text =
          _confirmPasswordController.text;
      registerController.role.value = _selectedRole!;

      await registerController.register();

      if (registerController.errorMessage.isEmpty) {
        _showSnackBar("Account created successfully!", isError: false);
        Get.offNamed('/login');
      } else {
        PopupService.error(registerController.errorMessage.value.toString());
      }
    } catch (e) {
      PopupService.error('registration_failed'.tr);
      debugPrint("Registration Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleSocialRegister(String provider) {
    _showSnackBar(
      'Sign up with $provider not yet implemented.',
      isError: false,
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    bool isTablet = false,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: isTablet ? 24 : 20,
      ),
      labelText: label,
      labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(focused: true),
      errorBorder: _inputBorder(error: true),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 20 : 16,
      ),
    );
  }

  InputDecoration _passwordInput(
    String label, {
    required bool obscure,
    required VoidCallback toggle,
    bool isTablet = false,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        Icons.lock_outline,
        color: Theme.of(context).colorScheme.primary,
        size: isTablet ? 24 : 20,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.primary,
          size: isTablet ? 24 : 20,
        ),
        onPressed: toggle,
      ),
      labelText: label,
      labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(focused: true),
      errorBorder: _inputBorder(error: true),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 20 : 16,
      ),
    );
  }

  InputBorder _inputBorder({bool focused = false, bool error = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color:
            error
                ? Theme.of(context).colorScheme.error
                : focused
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        width: focused ? 2 : 1,
      ),
    );
  }

  Widget _buildSocialButton(
    String iconPath,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 4),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            padding: EdgeInsets.symmetric(
              vertical: isTablet ? 16 : 12,
              horizontal: isTablet ? 16 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onTap,
          child: Image.asset(
            iconPath,
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    final maxWidth = isTablet ? 500.0 : size.width * 0.9;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.surface,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 20,
                vertical: isTablet ? 30 : 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  elevation: 12,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.shadow.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(isTablet),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildFormFields(isTablet),
                          SizedBox(height: isTablet ? 28 : 20),
                          _buildRoleSelector(isTablet),
                          SizedBox(height: isTablet ? 28 : 20),
                          _buildTermsCheckbox(isTablet),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildRegisterButton(isTablet),
                          SizedBox(height: isTablet ? 28 : 20),
                          _buildSocialSection(isTablet),
                          SizedBox(height: isTablet ? 28 : 20),
                          _buildLoginLink(isTablet),
                        ],
                      ),
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

  Widget _buildHeader(bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco,
            size: isTablet ? 80 : 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Text(
          'Krishi Link',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Create Your Account',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 20 : 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isTablet) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
          decoration: _inputDecoration(
            'Full Name',
            Icons.person,
            isTablet: isTablet,
          ),
          validator:
              (value) =>
                  value == null || value.trim().length < 3
                      ? 'Enter at least 3 characters'
                      : null,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        TextFormField(
          controller: _emailOrPhoneController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
          decoration: _inputDecoration(
            'Email or Phone',
            Icons.alternate_email,
            isTablet: isTablet,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an email or phone number';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
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
        SizedBox(height: isTablet ? 20 : 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
          decoration: _passwordInput(
            'Password',
            obscure: _obscurePassword,
            toggle: _togglePasswordVisibility,
            isTablet: isTablet,
          ),
          validator: (value) {
            if (value == null || value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Must contain at least one uppercase letter';
            }
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return 'Must contain at least one lowercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Must contain at least one number';
            }
            if (!RegExp(
              r'[!@#\$&*~%^()_+\-=\[\]{};:"\\|,.<>\/?]',
            ).hasMatch(value)) {
              return 'Must contain at least one special character';
            }
            return null;
          },
        ),
        SizedBox(height: isTablet ? 20 : 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
          decoration: _passwordInput(
            'Confirm Password',
            obscure: _obscureConfirmPassword,
            toggle: _toggleConfirmPasswordVisibility,
            isTablet: isTablet,
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelector(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Role',
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                'Farmer',
                Icons.agriculture,
                _selectedRole == 'farmer',
                () => setState(() => _selectedRole = 'farmer'),
                isTablet,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: _buildRoleCard(
                'Buyer',
                Icons.shopping_cart,
                _selectedRole == 'buyer',
                () => setState(() => _selectedRole = 'buyer'),
                isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isTablet ? 32 : 28,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreed,
          onChanged: (v) => setState(() => _agreed = v!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  text: "I agree to the ",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: "Terms of Service",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      height: isTablet ? 58 : 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: _isLoading ? 0 : 4,
          shadowColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isLoading ? null : _register,
        child:
            _isLoading
                ? SizedBox(
                  width: isTablet ? 24 : 20,
                  height: isTablet ? 24 : 20,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: isTablet ? 22 : 18),
                    SizedBox(width: isTablet ? 12 : 8),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSocialSection(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
              child: Text(
                'Or continue with',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Row(
          children: [
            _buildSocialButton(
              googleLogoPath,
              () => _handleSocialRegister('Google'),
              isTablet,
            ),
            _buildSocialButton(
              facebookLogoPath,
              () => _handleSocialRegister('Facebook'),
              isTablet,
            ),
            _buildSocialButton(
              appleLogoPath,
              () => _handleSocialRegister('Apple'),
              isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginLink(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        TextButton(
          onPressed: () => Get.to(() => const LoginScreen()),
          child: Text(
            'Login',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              fontSize: isTablet ? 16 : 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
