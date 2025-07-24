// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/features/admin/screens/admin_home_page.dart';
// import 'package:krishi_link/features/buyer/screens/buyer_home_page.dart';
// import 'package:krishi_link/features/farmer/screens/farmer_home_page.dart';

// class HomePage extends StatelessWidget {
//   final String userRole;

//   const HomePage({super.key, required this.userRole});

//   @override
//   Widget build(BuildContext context) {
//     // Show different UI based on role
//     //using switch case for role-based UI
//     switch (userRole) {
//       case 'farmer':
//         return FarmerHomePage();
//       case 'buyer':
//         return BuyerHomePage();
//       case 'admin':
//         return AdminHomePage();
//       default:
//         return Scaffold(body: Center(child: Text('unauthorized_access_message'.tr)));
//     }
//   }
// }
