// // lib/features/admin/screens/notifications_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/controllers/admin_notification_controller.dart';

// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AdminNotificationController controller =
//         Get.isRegistered()
//             ? Get.find<AdminNotificationController>()
//             : Get.put(AdminNotificationController());
//     final TextEditingController messageController = TextEditingController();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         backgroundColor: Colors.green.shade900,
//       ),
//       body: Obx(
//         () =>
//             controller.isLoading.value
//                 ? const Center(child: CircularProgressIndicator())
//                 : Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: messageController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Message',
//                               ),
//                             ),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.send),
//                             onPressed: () {
//                               if (messageController.text.isNotEmpty) {
//                                 controller.sendNotification(
//                                   messageController.text,
//                                 );
//                                 messageController.clear();
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: controller.notifications.length,
//                         itemBuilder: (context, index) {
//                           final notification = controller.notifications[index];
//                           return ListTile(
//                             title: Text(notification['message']),
//                             subtitle: Text(notification['date'].toString()),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }
