import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// IMPORTANT: Namespace to avoid hitting an old duplicate class at runtime.
import 'package:krishi_link/core/components/app_text_input_field.dart'
    as custom;
import 'package:krishi_link/core/components/send_button/app_send_button.dart';

import 'package:krishi_link/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/features/ai_chat/ai_chat_controller.dart';

class AiChatScreen extends StatefulWidget {
  final String name;
  const AiChatScreen({super.key, required this.name});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final FocusNode _textFieldFocusNode;
  Timer? _debounceTimer;
  late final AiChatController controller;

  @override
  void initState() {
    super.initState();
    controller =
        Get.isRegistered<AiChatController>()
            ? Get.find<AiChatController>()
            : Get.put(AiChatController());
    controller.setUserName(widget.name);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _textFieldFocusNode = FocusNode()..addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.scrollToBottom();
      _animationController.forward();
    });
  }

  void _onFocusChange() {
    if (_textFieldFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textFieldFocusNode.removeListener(_onFocusChange);
    _textFieldFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _AppBar(
            userName: widget.name,
            onClearChat: () => _showClearChatDialog(theme),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _ChatArea(
                controller: controller,
                fadeAnimation: _fadeAnimation,
                userName: widget.name,
                keyboardHeight: keyboardHeight,
              ),
            ),
          ),
          _InputArea(
            controller: controller,
            focusNode: _textFieldFocusNode,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (controller.isLoading.value) return; // prevent double-submit
    if (controller.inputController.text.trim().isNotEmpty) {
      controller.sendMessage();
      HapticFeedback.lightImpact();
      Future.microtask(controller.scrollToBottom);
    }
  }

  void _showClearChatDialog(ThemeData theme) async {
    final cs = theme.colorScheme;
    HapticFeedback.lightImpact();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surface,
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: cs.error),
            const SizedBox(width: 8),
            Text(
              'clear_chat'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'clear_chat_confirmation'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'cancel'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('clear'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.clearChat();
      _animationController.forward(from: 0);
    }
  }
}

class _AppBar extends StatelessWidget {
  final String userName;
  final VoidCallback onClearChat;

  const _AppBar({required this.userName, required this.onClearChat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.90)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: theme.appBarTheme.foregroundColor ?? cs.onPrimary,
                  size: 24,
                ),
                onPressed: Get.back,
                tooltip: 'Back',
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cs.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Semantics(
                        label: 'KrishiLink AI Chatbot',
                        child: LottieWidget(
                          path: LottieAssets.aiLogo,
                          height: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KrishiLink AI',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Chatting with $userName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onPrimary.withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.appBarTheme.foregroundColor ?? cs.onPrimary,
                  size: 24,
                ),
                tooltip: 'clear_chat'.tr,
                onPressed: onClearChat,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  final AiChatController controller;
  final Animation<double> fadeAnimation;
  final String userName;
  final double keyboardHeight;

  const _ChatArea({
    required this.controller,
    required this.fadeAnimation,
    required this.userName,
    required this.keyboardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(color: cs.surface),
      child: Obx(() {
        if (controller.messages.isEmpty && !controller.isLoading.value) {
          return _EmptyState(userName: userName);
        }

        return ListView.builder(
          reverse: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            top: 10,
            bottom: 16,
          ),
          controller: controller.scrollController,
          itemCount:
              controller.messages.length + (controller.isLoading.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (controller.isLoading.value && index == 0) {
              return const _TypingIndicator();
            }

            final messageIndex = controller.isLoading.value ? index - 1 : index;
            final reversedIndex = controller.messages.length - 1 - messageIndex;

            return _MessageBubble(
              message: controller.messages[reversedIndex],
              userName: userName,
              fadeAnimation: fadeAnimation,
              screenWidth: screenWidth,
              index: reversedIndex,
              onRetry: () => controller.retryMessage(reversedIndex),
            );
          },
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String userName;
  const _EmptyState({required this.userName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LottieWidget(path: LottieAssets.aiLogo, height: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to KrishiLink AI!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by typing a message below',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 32),
            const _SuggestedQuestions(),
          ],
        ),
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions();

  final List<String> questions = const [
    'How can I improve my crop yield?',
    'What are the best farming practices?',
    'Tell me about seasonal farming',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = Get.find<AiChatController>();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          questions.map((question) {
            return InkWell(
              onTap: () {
                controller.inputController.text = question;
                controller.sendMessage();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline),
                ),
                child: Text(
                  question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // keep tiny logo + dots
                // (use your LottieWidget if desired)
                // LottieWidget(path: LottieAssets.aiLogo, height: 20),
                SizedBox(width: 8),
                TypingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String userName;
  final Animation<double> fadeAnimation;
  final double screenWidth;
  final int index;
  final VoidCallback onRetry;

  const _MessageBubble({
    required this.message,
    required this.userName,
    required this.fadeAnimation,
    required this.screenWidth,
    required this.index,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isUser = message['role'] == 'user';
    final bg = isUser ? cs.primary : cs.surface;
    final fg = isUser ? cs.onPrimary : cs.onSurface;
    final timestamp = (message['timestamp'] as DateTime?)?.toLocal();
    final content = message['content'] ?? '';

    return FadeTransition(
      opacity: fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: LottieWidget(path: LottieAssets.aiLogo, height: 24),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: InkWell(
                onLongPress: () {
                  if (content.toString().isEmpty) return;
                  Clipboard.setData(ClipboardData(text: content.toString()));
                  Get.snackbar(
                    'Copied',
                    'Message text copied',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isUser
                              ? const Radius.circular(20)
                              : const Radius.circular(6),
                      bottomRight:
                          isUser
                              ? const Radius.circular(6)
                              : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            userName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      Text(
                        content.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg,
                          height: 1.45,
                          fontSize: 15,
                        ),
                      ),
                      if (timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  isUser
                                      ? cs.onPrimary.withOpacity(0.7)
                                      : cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      if (message['error'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text('retry'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: cs.error,
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final AiChatController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _ImagePickerButton(),
              const SizedBox(width: 12),
              Expanded(
                child: custom.AppTextInputField(
                  controller: controller.inputController,
                  focusNode: focusNode,
                  hint: 'type_your_message'.tr,
                  minLines: 1,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,

                  borderRadius: 22,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

                  // keep text visible above keyboard
                  scrollPadding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 80,
                  ),

                  // disable built-ins
                  showClearButton: false,
                  showSendButton: false,

                  // 👇 inject the reusable, GetX-free send button
                  suffixIcon: Obx(() {
                    final isLoading =
                        controller
                            .isLoading
                            .value; // reactive via GetX (optional)
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable:
                          controller
                              .inputController, // pure Flutter text updates
                      builder: (_, value, __) {
                        final hasText = value.text.trim().isNotEmpty;
                        return AppSendButton(
                          isLoading: isLoading,
                          hasText: hasText,
                          onSend: onSend,
                          inline: false, // fit nicely inside the field
                          iconSize: 20,
                        );
                      },
                    );
                  }),

                  onChanged:
                      (v) =>
                          controller.inputText.value =
                              v, // keep your GetX state too
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  const _ImagePickerButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          Icons.add_photo_alternate_outlined,
          color: cs.onSurface.withOpacity(0.65),
          size: 24,
        ),
        tooltip: 'send_image'.tr,
        onPressed: () => _showImageUploadSnackbar(context),
      ),
    );
  }

  void _showImageUploadSnackbar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Get.snackbar(
      'Coming Soon',
      'Image upload is an upcoming feature. For now, please send text only.',
      backgroundColor: cs.tertiaryContainer,
      colorText: cs.onTertiaryContainer,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(Icons.info_outline, color: cs.tertiary),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final v = (_animation.value - delay).clamp(0.0, 1.0);
            final scale = (1 - (v * 2 - 1).abs()).clamp(0.5, 1.0);
            final opacity = (1 - (v * 2 - 1).abs()).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
