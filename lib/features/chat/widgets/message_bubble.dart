import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'package:get/get.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onReplyTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onReplyTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isFromMe ? 50 : 0,
          right: message.isFromMe ? 0 : 50,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              message.isFromMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            if (message.replyToMessageId != null) _buildReplyPreview(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isFromMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromMe) _buildSenderName(),
                  _buildMessageContent(),
                  const SizedBox(height: 4),
                  _buildMessageTime(),
                ],
              ),
            ),
            _buildMessageStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
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
                  message.replyToMessageContent ?? '',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.senderName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );

      case MessageType.image:
        return _buildImageMessage();

      case MessageType.document:
        return _buildDocumentMessage();

      case MessageType.voice:
        return _buildVoiceMessage();

      case MessageType.video:
        return _buildVideoMessage();

      case MessageType.system:
        return _buildSystemMessage();

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.content,
              style: TextStyle(
                color: message.isFromMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl ?? '',
            placeholder:
                (context, url) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
            errorWidget:
                (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.mediaFileName ?? 'document'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (message.mediaFileSize != null)
                  Text(
                    _formatFileSize(message.mediaFileSize!),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download document
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'voice_message'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (message.mediaDuration != null)
                  Text(
                    '${(message.mediaDuration! / 1000).round()}s',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              // TODO: Play voice message
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              message.content,
              style: TextStyle(
                color: message.isFromMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.mediaThumbnail ?? message.mediaUrl ?? '',
                placeholder:
                    (context, url) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageTime() {
    return Text(
      DateFormat('HH:mm').format(message.timestamp),
      style: TextStyle(
        fontSize: 11,
        color:
            message.isFromMe
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey[600],
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!message.isFromMe) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (message.status) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
      default:
        return 'Sending';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
