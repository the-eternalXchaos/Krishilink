import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatThreadScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatThreadScreen({super.key, required this.chatRoom});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _chatController = Get.find<ChatController>();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupTypingListener();
  }

  void _loadMessages() {
    _chatController.loadMessages(widget.chatRoom.id);
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      final isTyping = _messageController.text.isNotEmpty;
      if (isTyping != _isTyping) {
        _isTyping = isTyping;
        _chatController.sendTypingIndicator(isTyping);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                widget.chatRoom.avatar != null
                    ? CachedNetworkImageProvider(widget.chatRoom.avatar!)
                    : null,
            child:
                widget.chatRoom.avatar == null
                    ? Text(
                      widget.chatRoom.name.isNotEmpty
                          ? widget.chatRoom.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Obx(() {
                  final isOnline =
                      _chatController.chatRooms
                          .firstWhereOrNull(
                            (room) => room.id == widget.chatRoom.id,
                          )
                          ?.isOnline ??
                      false;

                  return Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey[600],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                // TODO: Navigate to user profile
                break;
              case 'block':
                // TODO: Block user
                break;
              case 'clear':
                _showClearChatDialog();
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Clear Chat'),
                    ],
                  ),
                ),
              ],
        ),
      ],
      elevation: 1,
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      if (_chatController.isLoadingMessages.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_chatController.messages.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: _chatController.messages.length,
        itemBuilder: (context, index) {
          final message = _chatController.messages[index];
          final showDate = _shouldShowDate(index, message);

          return Column(
            children: [
              if (showDate) _buildDateDivider(message.timestamp),
              MessageBubble(
                message: message,
                onReplyTap: () {
                  _chatController.setReplyMessage(message);
                },
                onLongPress: () {
                  _showMessageOptions(message);
                },
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.chatRoom.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      if (_chatController.isTyping.value &&
          _chatController.typingUser.value.isNotEmpty) {
        return const TypingIndicator();
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(  
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(),
            const SizedBox(width: 8),
            Expanded(child: _buildMessageTextField()),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.attach_file),
      onSelected: (value) {
        switch (value) {
          case 'camera':
            _pickImage(ImageSource.camera);
            break;
          case 'gallery':
            _pickImage(ImageSource.gallery);
            break;
          case 'document':
            _pickDocument();
            break;
          case 'location':
            _shareLocation();
            break;
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'camera',
              child: Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Camera'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'gallery',
              child: Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Gallery'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'document',
              child: Row(
                children: [
                  Icon(Icons.description),
                  SizedBox(width: 8),
                  Text('Document'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'location',
              child: Row(
                children: [
                  Icon(Icons.location_on),
                  SizedBox(width: 8),
                  Text('Location'),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildMessageTextField() {
    return Obx(() {
      final hasReply = _chatController.replyToMessage.value != null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasReply) _buildReplyPreview(),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                _sendMessage();
              }
            },
          ),
        ],
      );
    });
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reply to ${_chatController.replyToMessage.value?.senderName ?? ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _chatController.replyToMessage.value?.content ?? '',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              _chatController.clearReplyMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      final isSending = _chatController.isSendingMessage.value;

      return Container(
        decoration: BoxDecoration(
          color: hasText ? Colors.blue : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon:
              isSending
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Icon(Icons.send, color: Colors.white),
          onPressed: hasText && !isSending ? _sendMessage : null,
        ),
      );
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatController.sendMessage(content: text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _shouldShowDate(int index, Message message) {
    if (index == _chatController.messages.length - 1) return true;

    final nextMessage = _chatController.messages[index + 1];
    final difference = message.timestamp.difference(nextMessage.timestamp);
    return difference.inDays > 0;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    _chatController.setReplyMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Copy message to clipboard
                  },
                ),
                if (message.isFromMe)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Delete message
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text(
              'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Clear chat messages
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        // TODO: Upload image and send message
        debugPrint('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null) {
        // TODO: Upload document and send message
        debugPrint('Document picked: ${result.files.first.path}');
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    debugPrint('Share location');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
