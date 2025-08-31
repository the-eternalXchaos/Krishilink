import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_room.dart';

class PredefinedMessages extends StatelessWidget {
  final String farmerId;
  final String farmerName;
  final String productId;
  final String productName;
  final String productPrice;

  const PredefinedMessages({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.productId,
    required this.productName,
    required this.productPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,  
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Chat with $farmerName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quick messages:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickMessageButton(
                context,
                'Is this available?',
                Icons.check_circle_outline,
              ),
              _buildQuickMessageButton(
                context,
                'What\'s the best price?',
                Icons.price_check,
              ),
              _buildQuickMessageButton(
                context,
                'Can I see more photos?',
                Icons.photo_library,
              ),
              _buildQuickMessageButton(
                context,
                'Where is pickup location?',
                Icons.location_on,
              ),
              _buildQuickMessageButton(
                context,
                'Is delivery available?',
                Icons.local_shipping,
              ),
              _buildQuickMessageButton(
                context,
                'Tell me more about this product',
                Icons.info_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startCustomChat(context),
              icon: const Icon(Icons.chat),
              label: const Text('Start Custom Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessageButton(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _sendPredefinedMessage(context, message),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendPredefinedMessage(BuildContext context, String message) async {
    final ChatController chatController = Get.find<ChatController>();

    try {
      // Create or get existing chat room
      final chatRoom = await chatController.createChatRoom(
        participantId: farmerId,
        productId: productId,
        initialMessage: _buildProductMessage(message),
      );

      if (chatRoom != null) {
        // Navigate to chat thread
        Get.toNamed('/chat/thread', arguments: chatRoom);
      } else {
        // Show error message
        PopupService.error('Failed to start chat. Please try again.');
      }
    } catch (e) {
      PopupService.error('Error: $e');
    }
  }

  void _startCustomChat(BuildContext context) async {
    final ChatController chatController = Get.find<ChatController>();

    try {
      // Create chat room without initial message
      final chatRoom = await chatController.createChatRoom(
        participantId: farmerId,
        productId: productId,
      );

      if (chatRoom != null) {
        // Navigate to chat thread
        Get.toNamed('/chat/thread', arguments: chatRoom);
      } else {
        PopupService.error('Failed to start chat. Please try again.');
      }
    } catch (e) {
      PopupService.error('Error: $e');
    }
  }

  String _buildProductMessage(String userMessage) {
    return '''$userMessage

---
*Product Details:*
• Product: $productName
• Price: $productPrice
• Product ID: $productId

I'm interested in this product and would like to discuss further.''';
  }
}
