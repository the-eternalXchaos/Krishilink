import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishi_link/src/core/constants/app_spacing.dart';

class ChatMessageAdapter<T> {
  final bool Function(T) isFromMe;
  final String Function(T) text;
  final DateTime Function(T) createdAt;
  final String? Function(T)? status; // e.g., sending, sent, failed
  ChatMessageAdapter({
    required this.isFromMe,
    required this.text,
    required this.createdAt,
    this.status,
  });
}

class ChatView<T> extends StatefulWidget {
  final List<T> messages;
  final ChatMessageAdapter<T> adapter;
  final String otherDisplayName; // shows avatar letter for the other side
  final bool isSending;
  final Future<void> Function(String) onSend;
  final void Function(T message)? onMessageTap; // e.g., retry on failed
  final String hintText;

  const ChatView({
    super.key,
    required this.messages,
    required this.adapter,
    required this.otherDisplayName,
    required this.isSending,
    required this.onSend,
    this.onMessageTap,
    this.hintText = 'Type a message…',
  });

  @override
  State<ChatView<T>> createState() => _ChatViewState<T>();
}

class _ChatViewState<T> extends State<ChatView<T>> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  bool _isAtBottom = true;

  void _handleScrollChange() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.position.pixels;
    final atBottom = (max - offset) <= 24; // within 24px of bottom
    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  @override
  void initState() {
    super.initState();
    // On first build, jump to the latest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
    _scroll.addListener(_handleScrollChange);
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus) {
        // When the input gets focus (keyboard opens), keep the latest in view
        _scrollToBottom();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      _scrollToBottom();
    } else if (widget.messages.isNotEmpty && oldWidget.messages.isNotEmpty) {
      // If last message changed (e.g., status update), keep it in view
      if (widget.messages.last != oldWidget.messages.last) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_handleScrollChange);
    _scroll.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final msgs = widget.messages;

    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child:
                  msgs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          final m = msgs[index];
                          final showTs = _shouldShowTimestamp(index);
                          return Column(
                            children: [
                              if (showTs)
                                _buildTimestamp(widget.adapter.createdAt(m)),
                              _buildBubble(context, m, colorScheme),
                              if (index == msgs.length - 1)
                                const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
            ),
            _buildInputBar(colorScheme),
          ],
        ),
        if (!_isAtBottom && msgs.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 80 + keyboard,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: null,
                  mini: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
      ],
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
            'Start a conversation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;
    final prev = widget.adapter.createdAt(widget.messages[index - 1]);
    final cur = widget.adapter.createdAt(widget.messages[index]);
    return cur.difference(prev).inMinutes > 30;
  }

  Widget _buildTimestamp(DateTime ts) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        DateFormat('MMM dd, yyyy • HH:mm').format(ts.toLocal()),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, T message, ColorScheme cs) {
    final fromMe = widget.adapter.isFromMe(message);
    final text = widget.adapter.text(message);
    final status = widget.adapter.status?.call(message);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment:
            fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromMe) ...[
            CircleAvatar(
              radius: 16,
              child: Text(
                widget.otherDisplayName.isNotEmpty
                    ? widget.otherDisplayName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap:
                  widget.onMessageTap != null
                      ? () => widget.onMessageTap!(message)
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: fromMe ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: fromMe ? cs.onPrimary : cs.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat(
                            'HH:mm',
                          ).format(widget.adapter.createdAt(message).toLocal()),
                          style: TextStyle(
                            color: (fromMe ? cs.onPrimary : cs.onSurface)
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (fromMe && status != null) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(status, cs),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (fromMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status, ColorScheme cs) {
    switch (status) {
      case 'sending':
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.onPrimary.withValues(alpha: 0.7),
          ),
        );
      case 'sent':
        return Icon(
          Icons.check,
          size: 14,
          color: cs.onPrimary.withValues(alpha: 0.7),
        );
      case 'failed':
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
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
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: widget.isSending ? null : _handleSend,
              backgroundColor: cs.primary,
              child:
                  widget.isSending
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                      : Icon(Icons.send, color: cs.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await widget.onSend(text);
    _scrollToBottom();
  }
}
