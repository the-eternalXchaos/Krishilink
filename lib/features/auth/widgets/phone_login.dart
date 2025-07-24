// import 'package:flutter/material.dart';
// import 'package:krishi_link/features/auth/screens/register_screen.dart';

// class PhoneLogin extends StatelessWidget {
//   const PhoneLogin({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }

//   Widget _buildPhoneLoginForm(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Form(
//         key: _phoneFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Welcome back!",
//               style: Theme.of(context).textTheme.headlineLarge,
//             ),
//             const SizedBox(height: 30),
//             TextFormField(
//               controller: _inputController,
//               decoration: const InputDecoration(
//                 labelText: "Phone Number",
//                 prefixIcon: Icon(Icons.phone),
//                 hintText: "+9779XXXXXXXXX",
//               ),
//               keyboardType: TextInputType.phone,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your phone number';
//                 }
//                 if (!value.startsWith('+')) {
//                   return 'Include country code (e.g. +977)';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _login,
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : const Text("Send OTP"),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (_) => const RegisterScreen()),
//                 );
//               },
//               child: const Text("Don't have an account? Register here"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
