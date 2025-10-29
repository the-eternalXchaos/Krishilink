import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/chat/presentation/controllers/product_chat_controller.dart';
import 'package:krishi_link/src/features/chat/presentation/widgets/chat_view.dart';

class ProductChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String farmerName;
  final String emailOrPhone;
  final String? farmerId; // optional direct farmer ID

  const ProductChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
    this.farmerId,
  });

  @override
  State<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  late final ProductChatController controller;
  // Using shared ChatView with its own controllers; keep minimal state here.

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ProductChatController(
        productId: widget.productId,
        productName: widget.productName,
        farmerIdParam: widget.farmerId,
      ),
    );
    // Auto-scroll handled by ChatView; no local controller needed.
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Guard: if guest somehow navigates here, pop back
    final auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('login_required'.tr, 'please_login_to_access'.tr);
        Get.back();
      });
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
              child: Text(
                widget.farmerName.isNotEmpty
                    ? widget.farmerName[0].toUpperCase()
                    : 'F',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.farmerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(
                    () => Text(
                      controller.isFarmerLive.value
                          ? 'online'.tr
                          : 'offline'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isFarmerLive.value
                    ? Icons.circle
                    : Icons.circle_outlined,
                color:
                    controller.isFarmerLive.value ? Colors.green : Colors.grey,
                size: 14,
              ),
              tooltip: 'Refresh status',
              onPressed: controller.checkFarmerLiveStatus,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showProductInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chatting about: ${widget.productName}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // Force Obx to subscribe to messages by reading length and
              // pass an immutable snapshot so ChatView sees changes.
              final msgCount =
                  controller.messages.length; // ignore: unused_local_variable
              final msgs = controller.messages.toList(growable: false);
              return ChatView<Map<String, dynamic>>(
                messages: msgs,
                otherDisplayName: widget.farmerName,
                isSending: controller.isSendingMessage.value,
                adapter: ChatMessageAdapter<Map<String, dynamic>>(
                  isFromMe: (m) => m['senderId'] == 'me',
                  text: (m) => m['message']?.toString() ?? '',
                  createdAt:
                      (m) =>
                          DateTime.tryParse(m['createdAt'] ?? '')?.toLocal() ??
                          DateTime.now(),
                  status: (m) => m['status']?.toString(),
                ),
                onMessageTap: (m) {
                  if ((m['status'] as String?) == 'failed') {
                    _showRetryDialog(m);
                  }
                },
                onSend: (text) async {
                  await controller.sendMessage(text);
                },
                hintText: 'type_a_message_dots'.tr,
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('message_failed'.tr),
            content: const Text(
              'This message failed to send. Would you like to retry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.retryMessage(message);
                },
                child: Text('retry'.tr),
              ),
            ],
          ),
    );
  }

  void _showProductInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Product', widget.productName),
                _buildInfoRow('Farmer', widget.farmerName),
                _buildInfoRow('Contact', widget.emailOrPhone),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
