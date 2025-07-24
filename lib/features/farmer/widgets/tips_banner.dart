import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';

class TipsBanner extends StatelessWidget {
  const TipsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FarmerController>();
    final theme = Theme.of(context);

    return Obx(
      () => Card(
        color: theme.colorScheme.primaryContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Tips',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${controller.crops.isNotEmpty ? controller.crops.first.suggestions : 'Add crops to get personalized tips.'} ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:animate_do/animate_do.dart';
// import 'package:krishi_link/features/farmer/controller/farmer_controller.dart';

// class TipsBanner extends StatelessWidget {
//   const TipsBanner({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<FarmerController>();
//     final theme = Theme.of(context);

//     return Obx(() {
//       // Aggregate tips from crops and weather
//       String? tip = _getTip(controller);
//       return SlideInLeft(
//         duration: const Duration(milliseconds: 600),
//         child: Card(
//           elevation: 3,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           color: theme.colorScheme.primaryContainer,
//           child: InkWell(
//             onTap: () {
//               if (tip.isNotEmpty) {
//                 Get.snackbar(
//                   'Tip Details'.tr,
//                   tip,
//                   backgroundColor: theme.colorScheme.primary,
//                   colorText: theme.colorScheme.onPrimary,
//                 );
//               }
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.lightbulb_outline,
//                     color: theme.colorScheme.primary,
//                     size: 30,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       tip!.isEmpty ? 'No tips available'.tr : tip,
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: theme.colorScheme.onSurface,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   Icon(
//                     Icons.arrow_forward_ios,
//                     size: 16,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   String? _getTip(FarmerController controller) {
//     final weather = controller.weather.value;
//     final crops = controller.crops;

//     if (weather.temperature == 0 && crops.isEmpty) {
//       return '';
//     }

//     // Weather-based tips
//     if (weather.temperature > 30) {
//       return 'High temperature alert: Water your crops twice daily to prevent stress.'
//           .tr;
//     } else if (weather.condition.toLowerCase().contains('rain')) {
//       return 'Rainy weather: Avoid overwatering and check for fungal risks.'.tr;
//     }

//     // Crop-specific tips
//     for (var crop in crops) {
//       if (crop.status == 'At Risk' || crop.status == 'Diseased') {
//         return 'Attention: ${crop.name} is ${crop.status?.toLowerCase()}. Check care instructions.'
//             .tr;
//       }

// if (controller.crop.suggestions.isNotEmpty) {
//         return crop.suggestions?.tr;
//       }
//     }

//     return 'All crops are healthy. Maintain regular care.'.tr;
//   }
// }
