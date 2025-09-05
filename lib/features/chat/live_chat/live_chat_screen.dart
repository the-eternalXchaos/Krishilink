// lib/features/live_chat/live_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'live_chat_controller.dart';
import 'package:krishi_link/core/components/app_text_input_field.dart';

class LiveChatScreen extends StatelessWidget {
  final String productId;
  final String productName;
  final String farmerName;
  final String emailOrPhone;
  final String? receiverUserId; // when farmer opens buyer thread

  const LiveChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
    this.receiverUserId,
  });

  @override
  Widget build(BuildContext context) {
    // final authController =
    //     Get.isRegistered<AuthController>()
    //         ? Get.find<AuthController>()
    //         : Get.put(AuthController());
    final uniqueTag = 'chat-${productId}_${receiverUserId ?? 'self'}';
    final _controller = Get.put(
      LiveChatController(
        productId: productId,
        productName: productName,
        farmerName: farmerName,
        emailOrPhone: emailOrPhone,
        receiverUserId: receiverUserId,
      ),
      tag: uniqueTag,
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                farmerName.isNotEmpty ? farmerName[0].toUpperCase() : '?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() {
                    final live = _controller.isOnline.value;
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
                            color:
                                live
                                    ? Colors.green
                                    : theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.85),
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
          // Context bar
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.local_florist),
              title: Text(
                productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                emailOrPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = _controller.messages;
              if (messages.isEmpty) {
                return Center(child: Text('say_hi'.tr));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  final mine =
                      m.senderId == (_controller.currentUserId ?? 'me');
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFA5D6A7) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 2,
                            spreadRadius: 0.5,
                            color: Color(0x19000000),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.body, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            m.createdAt.toLocal().toString().substring(0, 16),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Input
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller.inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted:
                          (_) =>
                              _controller.isSending.value
                                  ? null
                                  : _controller.send(),
                      onChanged: (v) {
                        // optional: typing indicator to hub
                        // ChatRealtimeService.I.typing(ctrl.conversationId, v.isNotEmpty);
                      },
                      decoration: InputDecoration(
                        hintText: 'type_a_message'.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => IconButton(
                      icon:
                          _controller.isSending.value
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.send),
                      onPressed:
                          _controller.isSending.value ? null : _controller.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
