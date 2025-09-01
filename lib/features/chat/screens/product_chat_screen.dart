import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/product_chat_controller.dart';
import '../models/simple_message.dart';

class ProductChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String farmerName;
  final String emailOrPhone;

  const ProductChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.farmerName,
    required this.emailOrPhone,
  });

  @override
  State<ProductChatScreen> createState() => _ProductChatScreenState();
}

class _ProductChatScreenState extends State<ProductChatScreen> {
  final ProductChatController controller = Get.put(ProductChatController());
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await controller.initializeChatForProduct(
      productId: widget.productId,
      productName: widget.productName,
      farmerName: widget.farmerName,
      emailOrPhone: widget.emailOrPhone,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
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
                  ),
                  Obx(
                    () => Text(
                      controller.isFarmerLive.value ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimary.withOpacity(0.8),
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
                size: 12,
              ),
              onPressed: controller.checkFarmerLiveStatus,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showProductInfo(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Product info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
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
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isLastMessage = index == controller.messages.length - 1;
                  final showTimestamp = _shouldShowTimestamp(index);

                  return Column(
                    children: [
                      if (showTimestamp) _buildTimestamp(message.timestamp),
                      _buildMessageBubble(message, colorScheme),
                      if (isLastMessage) const SizedBox(height: 8),
                    ],
                  );
                },
              );
            }),
          ),

          // Message input
          _buildMessageInput(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with ${widget.farmerName}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about ${widget.productName}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        DateFormat('MMM dd, yyyy • HH:mm').format(timestamp),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildMessageBubble(SimpleMessage message, ColorScheme colorScheme) {
    final isFromMe = message.isFromMe;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Text(
                widget.farmerName.isNotEmpty
                    ? widget.farmerName[0].toUpperCase()
                    : 'F',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: GestureDetector(
              onTap: () {
                if (message.status == MessageStatus.failed) {
                  _showRetryDialog(message);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isFromMe
                          ? colorScheme.primary
                          : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color:
                            isFromMe
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            color: (isFromMe
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant)
                                .withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          _buildMessageStatusIcon(message.status, colorScheme),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isFromMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(
    MessageStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onPrimary.withOpacity(0.7),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: colorScheme.onPrimary.withOpacity(0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: colorScheme.onPrimary.withOpacity(0.7),
        );
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Colors.blue);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: Colors.red);
    }
  }

  Widget _buildMessageInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  controller.messageText.value = value;
                },
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => FloatingActionButton.small(
                onPressed:
                    controller.isSendingMessage.value ? null : _sendMessage,
                backgroundColor: colorScheme.primary,
                child:
                    controller.isSendingMessage.value
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        : Icon(Icons.send, color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    controller.messageText.value = messageController.text.trim();
    messageController.clear();
    controller.sendMessage();
    _scrollToBottom();
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;

    final currentMessage = controller.messages[index];
    final previousMessage = controller.messages[index - 1];

    final timeDifference = currentMessage.timestamp.difference(
      previousMessage.timestamp,
    );
    return timeDifference.inMinutes > 30;
  }

  void _showRetryDialog(SimpleMessage message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Message Failed'),
            content: const Text(
              'This message failed to send. Would you like to retry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.retryMessage(message);
                },
                child: const Text('Retry'),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
