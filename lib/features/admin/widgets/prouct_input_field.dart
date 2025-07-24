// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:krishi_link/core/utils/constants.dart';

// class ProductInputField extends StatelessWidget {
//   final String label;
//   final TextEditingController controller;
//   final TextInputType keyboardType;
//   final int maxLines;

//   const ProductInputField({
//     super.key,
//     required this.label,
//     required this.controller,
//     this.keyboardType = TextInputType.text,
//     this.maxLines = 1,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: padding,
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           labelText: label.tr,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }
// }

// Updated ProductInputField to support validation
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const ProductInputField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label.tr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: Icon(
            _getIconForLabel(label),
            color: Theme.of(context).primaryColor,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withAlpha(25),
        ),
        validator: validator,
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'product_name':
        return Icons.label;
      case 'rate':
        return Icons.monetization_on;
      case 'quantity':
        return Icons.production_quantity_limits;
      case 'location':
        return Icons.location_on;
      case 'description':
        return Icons.description;
      case 'farmer_phone':
        return Icons.contact_phone;
      default:
        return Icons.text_fields;
    }
  }
}

// Extension for string capitalization
extension MyStringCapitalizer on String {
  String get capitalizeFirst {
    return isEmpty
        ? ''
        : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
