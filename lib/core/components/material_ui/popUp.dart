// import 'package:get/get.dart';
// import 'package:krishi_link/core/utils/constants.dart';
// import 'package:krishi_link/core/lottie/popup_service.dart';
// import 'package:lottie/lottie.dart';

// enum PopupType {
//   success,
//   error,
//   warning,
//   info,
//   addedToCart,
//   orderPlaced,
//   userLoading,
// }

// class Popup extends StatefulWidget {
//   final PopupType type;
//   final String title;
//   final String message;
//   final bool autoDismiss;

//   const Popup({
//     super.key,
//     required this.type,
//     required this.title,
//     required this.message,
//     this.autoDismiss = true, // Default to true for auto-dismiss
//   });

//   @override
//   State<Popup> createState() => _PopupState();
// }

// class _PopupState extends State<Popup> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600), // Smooth and slow
//     );

//     _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOutBack,
//     );

//     _controller.forward();

//     // Auto dismiss logic
//     if (widget.autoDismiss) {
//       Future.delayed(const Duration(seconds: 3), () {
//         if (mounted && Navigator.canPop(context)) {
//           Navigator.pop(context);
//         }
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   String _getLottieAsset() {
//     switch (widget.type) {
//       case PopupType.success:
//         return 'lib/core/components/lottie/Success.json';
//       case PopupType.error:
//         return 'lib/core/components/lottie/Error.json';
//       case PopupType.warning:
//         return 'lib/core/components/lottie/warning.json';

//       case PopupType.info:
//         return 'lib/core/components/lottie/emptyCart.json';
//       case PopupType.addedToCart:
//         return 'lib/core/components/lottie/added_to_cart.json';
//       case PopupType.orderPlaced:
//         return 'lib/core/components/lottie/order_placed.json';
//       case PopupType.userLoading:
//         return profileLoading;
//     }
//   }

//   Color _getColor() {
//     switch (widget.type) {
//       case PopupType.success:
//         return Colors.green;
//       case PopupType.error:
//         return Colors.red;
//       case PopupType.warning:
//         return Colors.orange;
//       case PopupType.info:
//         return Colors.blue;
//       case PopupType.addedToCart:
//         return Colors.teal;
//       case PopupType.orderPlaced:
//         return Colors.deepPurple;
//       case PopupType.userLoading:
//         return Colors.green;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: ScaleTransition(
//         scale: _scaleAnimation,
//         child: AlertDialog(
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Lottie.asset(_getLottieAsset(), height: 150, repeat: false),
//               const SizedBox(height: 16),
//               Text(
//                 widget.title,
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: _getColor(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(widget.message, textAlign: TextAlign.center),
//               const SizedBox(height: 16),
//               TextButton(onPressed: () => Get.back(), child: Text("ok".tr)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
