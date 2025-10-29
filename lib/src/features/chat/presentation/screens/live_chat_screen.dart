// lib/src/features/chat/presentation/screens/live_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/features/chat/data/chat_services.dart';
import 'package:krishi_link/src/features/chat/models/live_chat_model.dart';
import 'package:krishi_link/src/features/chat/presentation/controllers/live_chat_controller.dart';
import 'package:krishi_link/src/features/chat/presentation/widgets/chat_view.dart';
import 'package:signalr_netcore/signalr_client.dart';

class LiveChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String farmerName; // other party display name
  final String emailOrPhone;
  final String? receiverUserId; // set when farmer opens buyer thread

  const LiveChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
    this.receiverUserId,
  });

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  @override
  Widget build(BuildContext context) {
    final authController =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());

    // Guard for guest
    if (!authController.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'login_required'.tr,
          'please_login_to_access'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
      });
      return const SizedBox.shrink();
    }

    final uniqueTag =
        'chat-${widget.productId}_${widget.receiverUserId ?? 'self'}';
    final controller =
        Get.isRegistered<LiveChatController>(tag: uniqueTag)
            ? Get.find<LiveChatController>(tag: uniqueTag)
            : Get.put(
              LiveChatController(
                productId: widget.productId,
                productName: widget.productName,
                farmerName: widget.farmerName,
                emailOrPhone: widget.emailOrPhone,
                receiverUserId: widget.receiverUserId,
              ),
              tag: uniqueTag,
            );

    final theme = Theme.of(context);
    final isFarmerThread = widget.receiverUserId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.2,
              ),
              child: Text(
                widget.farmerName.isNotEmpty
                    ? widget.farmerName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.farmerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // Presence indicator
                  isFarmerThread
                      ? StreamBuilder<HubConnectionState>(
                        stream: ChatService.I.connectionState,
                        initialData:
                            ChatService.I.isConnected
                                ? HubConnectionState.Connected
                                : HubConnectionState.Disconnected,
                        builder: (context, snapshot) {
                          final connected =
                              snapshot.data == HubConnectionState.Connected;
                          return Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: connected ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connected ? 'live'.tr : 'not_connected'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                      : Obx(() {
                        final live = controller.isOnline.value;
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: live ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              live ? 'online'.tr : 'offline'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Context bar (product name or fallback)
          Builder(
            builder: (_) {
              final product = widget.productName.trim();
              final contextText =
                  product.isNotEmpty
                      ? 'Chatting about: $product'
                      : (widget.farmerName.trim().isNotEmpty
                          ? 'Chatting with: ${widget.farmerName}'
                          : '');
              if (contextText.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      product.isNotEmpty ? Icons.local_florist : Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        contextText,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Messages + input (shared view)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              // Force subscription to messages and pass a snapshot for rebuilds
              final msgCount =
                  controller.messages.length; // ignore: unused_local_variable
              final msgs = controller.messages.toList(growable: false);
              return ChatView<LiveChatMessage>(
                messages: msgs,
                otherDisplayName: widget.farmerName,
                isSending: controller.isSending.value,
                adapter: ChatMessageAdapter<LiveChatMessage>(
                  isFromMe:
                      (m) => m.senderId == (controller.currentUserId ?? 'me'),
                  text: (m) => m.body,
                  createdAt: (m) => m.createdAt,
                ),
                onSend: (text) async {
                  controller.inputCtrl.text = text;
                  await controller.send();
                },
                hintText: 'type_a_message_dots'.tr,
              );
            }),
          ),
        ],
      ),
    );
  }
}
