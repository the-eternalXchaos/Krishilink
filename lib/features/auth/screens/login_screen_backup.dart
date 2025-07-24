// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/components/material_ui/popup.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/features/auth/controller/auth_controller.dart';
// import 'package:krishi_link/features/auth/widgets/social_iconbutton.dart';
// import 'package:krishi_link/services/popup_service.dart';
// import 'package:lottie/lottie.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen>
//     with SingleTickerProviderStateMixin {
//   final _otpFormKey = GlobalKey<FormState>();
//   final _credentialFormKey = GlobalKey<FormState>();
//   final _identifierController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscureText = true;
//   late TabController _tabController;
//   final AuthController authController = Get.put(AuthController());
//   // final _tabAnimDuration = const Duration(milliseconds: 300);

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _tabController.addListener(_handleTabChange);
//   }

//   void _handleTabChange() {
//     if (_tabController.indexIsChanging) {
//       setState(() {}); // Force rebuild when tab changes
//     }
//   }

//   Future<void> _sendOtpLogin() async {
//     if (!_otpFormKey.currentState!.validate()) return;

//     final identifier = _identifierController.text.trim();

//     try {
//       await authController.sendOtp(identifier);
//       Get.toNamed('/otp-verify', arguments: {'identifier': identifier});
//     } catch (e) {
//       PopupService.show(type: PopupType.error, message: "$e", title: 'Error');
//     }
//   }

//   Future<void> _passwordLogin() async {
//     if (!_credentialFormKey.currentState!.validate()) return;

//     final identifier = _identifierController.text.trim();
//     final password = _passwordController.text;
//     // final isEmail = _isValidEmail(identifier);

//     try {
//       await authController.passwordLogin(
//         identifier,
//         password,
//         deviceId,
//         // isEmail: isEmail,
//       );
//       if (authController.currentUser.value != null) {
//         _navigateBasedOnRole(authController.currentUser.value!.role);
//       }
//     } catch (e) {
//       PopupService.show(type: PopupType.error, message: "$e", title: 'Error');
//     }
//   }

//   bool _isValidEmail(String input) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
//   }

//   bool _isValidNepaliPhone(String input) {
//     return RegExp(r'^(?:\+977|977)?\d{10}$').hasMatch(input);
//   }

//   // scaffold
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       // backgroundColor: Colors.amber,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Theme.of(context).colorScheme.primaryContainer,
//               Theme.of(context).colorScheme.secondaryContainer,
//               Theme.of(context).colorScheme.tertiaryContainer,
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     _buildHeaderSection(),
//                     const SizedBox(height: 30),
//                     _buildLoginCard(),
//                     const SizedBox(height: 30),
//                     _buildSocialLoginSection(),
//                     const SizedBox(height: 30),
//                     _buildRegistrationLink(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderSection() {
//     return Column(
//       children: [
//         Lottie.asset(
//           farmerIllustration,

//           // height: 900,
//           // width: 900,
//           repeat: true,
//           reverse: true,
//           animate: true,
//         ),
//         Text(
//           "Welcome to KrishiLink",
//           style: Theme.of(context).textTheme.headlineLarge?.copyWith(
//             color: Theme.of(context).colorScheme.primary,
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.center,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           "Nepal's Agricultural Network",
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             color: Theme.of(context).colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoginCard() {
//     return Card(
//       elevation: 8,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _buildAuthTypeSelector(),
//             const SizedBox(height: 20),
//             SizedBox(
//               height: 160,
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [_buildOtpForm(), _buildCredentialForm()],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildLoginButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAuthTypeSelector() {
//     return Container(
//       height: 80,
//       decoration: BoxDecoration(
//         color: Theme.of(
//           context,
//         ).colorScheme.surfaceContainerHighest.withAlpha(30),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TabBar(
//         controller: _tabController,
//         labelColor: Theme.of(context).colorScheme.primary,
//         unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
//         labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//         unselectedLabelStyle: const TextStyle(
//           fontWeight: FontWeight.normal,
//           fontSize: 14,
//         ),
//         indicator: UnderlineTabIndicator(
//           borderSide: BorderSide(
//             width: 3.0,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//           insets: const EdgeInsets.only(bottom: 12),
//         ),
//         tabs: [
//           Tab(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.sms_outlined,
//                   size: 24,
//                   color:
//                       _tabController.index == 0
//                           ? Theme.of(context).colorScheme.primary
//                           : Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//                 const SizedBox(height: 6),
//                 const Text('OTP Login'),
//               ],
//             ),
//           ),
//           Tab(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.lock_outline,
//                   size: 24,
//                   color:
//                       _tabController.index == 1
//                           ? Theme.of(context).colorScheme.primary
//                           : Theme.of(context).colorScheme.onSurfaceVariant,
//                 ),
//                 const SizedBox(height: 6),
//                 const Text('Password Login'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOtpForm() {
//     return Form(
//       key: _otpFormKey,
//       child: Column(
//         children: [
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: _identifierController,
//             decoration: InputDecoration(
//               labelText: "Email or Phone Number",
//               prefixIcon: Icon(
//                 Icons.phone_android,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               hintText: "example@domain.com / 9XXXXXXXXX",
//               border: _inputBorder(),
//               filled: true,
//               fillColor: Theme.of(context).colorScheme.surface,
//             ),
//             keyboardType: TextInputType.emailAddress,
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter email or phone number';
//               }
//               if (!_isValidEmail(value) && !_isValidNepaliPhone(value)) {
//                 return 'Enter valid email or Nepali phone number';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 20),
//           Text(
//             "We'll send an OTP to your email/phone",
//             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//               color: Theme.of(context).colorScheme.onSurfaceVariant,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   //TODO move the widget to their folder after completion
//   Widget _buildCredentialForm() {
//     return Form(
//       key: _credentialFormKey,
//       child: Column(
//         children: [
//           const SizedBox(height: 8),
//           TextFormField(
//             controller: _identifierController,
//             decoration: InputDecoration(
//               labelText: "Email/Phone",
//               prefixIcon: Icon(
//                 Icons.person_outline,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               hintText: "Enter email or phone",
//               border: _inputBorder(),
//               filled: true,
//               fillColor: Theme.of(context).colorScheme.surface,
//             ),
//             autovalidateMode: AutovalidateMode.onUserInteraction,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter email or phone';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 20),
//           TextFormField(
//             controller: _passwordController,
//             obscureText: _obscureText,
//             decoration: InputDecoration(
//               labelText: "Password",
//               prefixIcon: Icon(
//                 Icons.lock_outline,
//                 color: Theme.of(context).colorScheme.primary,
//               ),
//               suffixIcon: IconButton(
//                 icon: Icon(
//                   _obscureText ? Icons.visibility_off : Icons.visibility,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 onPressed: () => setState(() => _obscureText = !_obscureText),
//               ),
//               border: _inputBorder(),
//               filled: true,
//               fillColor: Theme.of(context).colorScheme.surface,
//             ),
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please enter password';
//               }
//               if (value.length < 6) return 'Password must be 6+ characters';
//               return null;
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   InputBorder _inputBorder() {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
//     );
//   }

//   Widget _buildLoginButton() {
//     return Obx(() {
//       return ElevatedButton.icon(
//         icon:
//             authController.isLoading.value
//                 ? const SizedBox.shrink()
//                 : Icon(
//                   _tabController.index == 0 ? Icons.sms : Icons.login,
//                   color: Theme.of(context).colorScheme.onPrimary,
//                 ),
//         label:
//             authController.isLoading.value
//                 ? CircularProgressIndicator(
//                   color: Theme.of(context).colorScheme.onPrimary,
//                 )
//                 : Text(
//                   _tabController.index == 0 ? 'Send OTP' : 'Sign In',
//                   style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                     color: Theme.of(context).colorScheme.onPrimary,
//                   ),
//                 ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           minimumSize: const Size(double.infinity, 50),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         onPressed:
//             authController.isLoading.value
//                 ? null
//                 : _tabController.index == 0
//                 ? _sendOtpLogin
//                 : _passwordLogin,
//       );
//     });
//   }

//   // Widget _buildSocialLoginSection() {
//   //   return Column(
//   //     children: [
//   //       Text(
//   //         'Or continue with',
//   //         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//   //           color: Theme.of(context).colorScheme.onSurfaceVariant,
//   //         ),
//   //       ),
//   //       const SizedBox(height: 20),
//   //       Row(
//   //         mainAxisAlignment: MainAxisAlignment.center,
//   //         children: [
//   //           buildSocialButton(googleLogoPath, 'Google'),
//   //           const SizedBox(width: 20),
//   //           buildSocialButton(facebookLogoPath, 'Facebook'),
//   //           const SizedBox(width: 20),
//   //           buildSocialButton(appleLogoPath, 'Apple'),
//   //         ],
//   //       ),
//   //     ],
//   //   );
//   // }
//   Widget _buildSocialLoginSection() {
//     return Column(
//       children: [
//         Text(
//           'Or continue with',
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: Theme.of(context).colorScheme.onSurfaceVariant,
//           ),
//         ),
//         const SizedBox(height: 20),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SocialIconButton(
//               iconPath: googleLogoPath,
//               onTap: () => _handleSocialLogin('Google'),
//             ),
//             const SizedBox(width: 30),
//             SocialIconButton(
//               iconPath: facebookLogoPath,
//               onTap: () => _handleSocialLogin('Facebook'),
//             ),
//             const SizedBox(width: 30),
//             SocialIconButton(
//               iconPath: appleLogoPath,
//               onTap: () => _handleSocialLogin('Apple'),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget buildSocialButton(String iconPath, String label) {
//     return ConstrainedBox(
//       constraints: BoxConstraints(
//         maxWidth: 120, // Fixed maximum width
//         minWidth: 80, // Minimum width
//       ),
//       child: OutlinedButton.icon(
//         icon: Image.asset(
//           iconPath,
//           width: 20, // Reduced icon size
//           height: 20,
//           fit: BoxFit.contain, // Ensures proper fitting
//         ),
//         label: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12, // Smaller font size
//           ),
//         ),
//         style: OutlinedButton.styleFrom(
//           foregroundColor: Theme.of(context).colorScheme.onSurface,
//           side: BorderSide(color: Theme.of(context).colorScheme.outline),
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10), // Slightly smaller radius
//           ),
//         ),
//         onPressed: () => _handleSocialLogin(label),
//       ),
//     );
//   }

//   Widget _buildRegistrationLink() {
//     return GestureDetector(
//       onTap: () => Get.offAllNamed('/register'),
//       child: RichText(
//         text: TextSpan(
//           text: "New to KrishiLink? ",
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//             color: Theme.of(context).colorScheme.onSurfaceVariant,
//           ),
//           children: [
//             TextSpan(
//               text: "Create Account",
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.primary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleSocialLogin(String provider) {
//     switch (provider.toLowerCase()) {
//       case 'google':
//         authController.loginWithGoogle();
//         break;
//       case 'facebook':
//         authController.loginWithFacebook();
//         break;
//       case 'apple':
//         authController.loginWithApple();
//         break;
//     }
//   }

//   @override
//   void dispose() {
//     _identifierController.dispose();
//     _passwordController.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _navigateBasedOnRole(String role) {
//     final route = switch (role.toLowerCase()) {
//       'admin' => '/admin-dashboard',
//       'farmer' => '/farmer-dashboard',
//       'buyer' => '/buyer-dashboard',
//       _ => '/home', // Default fallback
//     };

//     // Clear navigation stack and redirect
//     Get.offAllNamed(route);
//   }
// }
