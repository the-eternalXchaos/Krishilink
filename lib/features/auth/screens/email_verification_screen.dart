// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class EmailVerificationScreen extends StatefulWidget {
//   final String email;

//   const EmailVerificationScreen({super.key, required this.email});

//   @override
//   State<EmailVerificationScreen> createState() =>
//       _EmailVerificationScreenState();
// }

// class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
//   bool _isLoading = false;
//   bool _isVerified = false;
//   bool _emailSent = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkEmailVerified();
//   }

//   Future<void> _checkEmailVerified() async {
//     setState(() => _isLoading = true);
//     await FirebaseAuth.instance.currentUser?.reload();
//     final user = FirebaseAuth.instance.currentUser;
//     setState(() {
//       _isVerified = user?.emailVerified ?? false;
//       _isLoading = false;
//     });

//     if (_isVerified) {
//       // Navigate to home screen or login screen after verification
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   Future<void> _resendVerificationEmail() async {
//     setState(() {
//       _isLoading = true;
//       _emailSent = false;
//     });

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user != null && !user.emailVerified) {
//         await user.sendEmailVerification();
//         setState(() => _emailSent = true);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Email Verification')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Icon(Icons.email, size: 100, color: Colors.blue),
//             const SizedBox(height: 20),
//             Text(
//               _isVerified ? 'Email Verified!' : 'Verify Your Email',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Verification email sent to:',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             Text(
//               widget.email,
//               style: Theme.of(
//                 context,
//               ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             if (_isLoading)
//               const CircularProgressIndicator()
//             else if (_isVerified)
//               const Text('Your email has been successfully verified!')
//             else
//               Column(
//                 children: [
//                   const Text(
//                     'Please check your inbox and click the verification link.',
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _resendVerificationEmail,
//                     child: const Text('Resend Verification Email'),
//                   ),
//                   if (_emailSent)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 10),
//                       child: Text(
//                         'Verification email sent!',
//                         style: TextStyle(color: Colors.green),
//                       ),
//                     ),
//                 ],
//               ),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: _checkEmailVerified,
//               child: const Text('Check Verification Status'),
//             ),
//             const SizedBox(height: 20),
//             TextButton(
//               onPressed: () {
//                 FirebaseAuth.instance.signOut();
//                 Navigator.pushReplacementNamed(context, '/login');
//               },
//               child: const Text('Return to Login'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
