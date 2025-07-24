import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/constants/constants.dart';
import 'package:krishi_link/core/constants/lottie_assets.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/components/app_text_input_field.dart';

import 'ai_chat_controller.dart';

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
  final AiChatController controller = Get.put(AiChatController());

  @override
  void initState() {
    super.initState();
    controller.setUserName(widget.name);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _textFieldFocusNode = FocusNode();

    _textFieldFocusNode.addListener(_onFocusChange);
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
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _AppBar(
            userName: widget.name,
            onClearChat: () => _showClearChatDialog(isDarkMode),
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
    if (controller.inputText.value.trim().isNotEmpty) {
      controller.sendMessage();
      HapticFeedback.lightImpact();
    }
  }

  void _showClearChatDialog(bool isDarkMode) async {
    HapticFeedback.lightImpact();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingConstants.largeRadius),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[600]),
            const SizedBox(width: SpacingConstants.smallPadding),
            Text(
              'clear_chat'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'clear_chat_confirmation'.tr,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  SpacingConstants.mediumRadius,
                ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.green[800]!, Colors.green[700]!]
                  : [Colors.green[600]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: SpacingConstants.largePadding,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingConstants.largePadding,
            vertical: SpacingConstants.mediumPadding,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: SpacingConstants.iconSizeLarge,
                ),
                onPressed: Get.back,
                tooltip: 'Back',
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              isDarkMode
                                  ? [Colors.grey[800]!, Colors.grey[700]!]
                                  : [Colors.green[100]!, Colors.green[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          SpacingConstants.mediumRadius,
                        ),
                      ),
                      child: Semantics(
                        label: 'KrishiLink AI Chatbot',
                        child: LottieWidget(
                          path: LottieAssets.aiLogo,
                          height: SpacingConstants.lottieSizeLarge * 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: SpacingConstants.mediumPadding),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'KrishiLink AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Chatting with $userName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: SpacingConstants.iconSizeLarge,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [Colors.grey[50]!, Colors.green[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Obx(() {
        if (controller.messages.isEmpty && !controller.isLoading.value) {
          return _EmptyState(userName: userName);
        }

        return ListView.builder(
          reverse: true,
          padding: EdgeInsets.only(
            left: screenWidth * SpacingConstants.chatHorizontalPaddingFactor,
            right: screenWidth * SpacingConstants.chatHorizontalPaddingFactor,
            top: SpacingConstants.mediumPadding,
            bottom: SpacingConstants.largePadding,
          ),
          controller: controller.scrollController,
          itemCount:
              controller.messages.length + (controller.isLoading.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (controller.isLoading.value && index == 0) {
              return _TypingIndicator();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingConstants.extraLargePadding),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: SpacingConstants.extraLargePadding,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LottieWidget(
              path: LottieAssets.aiLogo,
              height: SpacingConstants.lottieSizeLarge,
            ),
          ),
          const SizedBox(height: SpacingConstants.extraLargePadding),
          Text(
            'Welcome to KrishiLink AI!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: SpacingConstants.smallPadding),
          Text(
            'Start a conversation by typing a message below',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SpacingConstants.extraLargePadding * 1.33),
          _SuggestedQuestions(),
        ],
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  final List<String> questions = [
    'How can I improve my crop yield?',
    'What are the best farming practices?',
    'Tell me about seasonal farming',
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<AiChatController>();

    return Wrap(
      spacing: SpacingConstants.smallPadding,
      runSpacing: SpacingConstants.smallPadding,
      children:
          questions
              .map(
                (question) => InkWell(
                  onTap: () {
                    controller.inputController.text = question;
                    controller.inputText.value = question;
                    controller.sendMessage();
                  },
                  borderRadius: BorderRadius.circular(
                    SpacingConstants.extraLargeRadius,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConstants.largePadding,
                      vertical: SpacingConstants.smallPadding,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(
                        SpacingConstants.extraLargeRadius,
                      ),
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      question,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingConstants.smallPadding,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(SpacingConstants.mediumPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDarkMode
                        ? [Colors.grey[800]!, Colors.grey[700]!]
                        : [Colors.white, Colors.green[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                SpacingConstants.extraLargeRadius,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: SpacingConstants.mediumRadius,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LottieWidget(
                  path: LottieAssets.aiLogo,
                  height: SpacingConstants.lottieSizeMedium,
                ),
                const SizedBox(width: SpacingConstants.smallPadding),
                const TypingIndicator(),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUser = message['role'] == 'user';
    final timestamp = (message['timestamp'] as DateTime?)?.toLocal();

    return FadeTransition(
      opacity: fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SpacingConstants.smallPadding / 2,
        ),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDarkMode
                            ? [Colors.green[800]!, Colors.green[700]!]
                            : [Colors.green[100]!, Colors.green[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: LottieWidget(
                  path: LottieAssets.aiLogo,
                  height: SpacingConstants.lottieSizeMedium,
                ),
              ),
              const SizedBox(width: SpacingConstants.smallPadding),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      screenWidth * SpacingConstants.messageMaxWidthFactor,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConstants.largePadding,
                  vertical: SpacingConstants.mediumPadding,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isUser
                            ? (isDarkMode
                                ? [Colors.green[700]!, Colors.green[600]!]
                                : [Colors.green[500]!, Colors.green[400]!])
                            : (isDarkMode
                                ? [Colors.grey[800]!, Colors.grey[700]!]
                                : [Colors.white, Colors.green[50]!]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(
                      SpacingConstants.extraLargeRadius,
                    ),
                    topRight: const Radius.circular(
                      SpacingConstants.extraLargeRadius,
                    ),
                    bottomLeft:
                        isUser
                            ? const Radius.circular(
                              SpacingConstants.extraLargeRadius,
                            )
                            : const Radius.circular(
                              SpacingConstants.smallRadius,
                            ),
                    bottomRight:
                        isUser
                            ? const Radius.circular(
                              SpacingConstants.smallRadius,
                            )
                            : const Radius.circular(
                              SpacingConstants.extraLargeRadius,
                            ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: SpacingConstants.mediumRadius,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUser)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: SpacingConstants.smallPadding / 2,
                        ),
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      message['content'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isUser
                                ? Colors.white
                                : (isDarkMode
                                    ? Colors.white
                                    : Colors.grey[800]),
                        height: 1.4,
                      ),
                    ),
                    if (timestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: SpacingConstants.smallPadding / 2,
                        ),
                        child: Text(
                          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isUser
                                    ? Colors.white.withOpacity(0.7)
                                    : (isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[500]),
                          ),
                        ),
                      ),
                    if (message['error'] == true)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: SpacingConstants.smallPadding,
                        ),
                        child: TextButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(
                            Icons.refresh,
                            size: SpacingConstants.iconSizeSmall,
                          ),
                          label: Text('retry'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingConstants.smallPadding,
                              vertical: SpacingConstants.smallPadding / 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: SpacingConstants.smallPadding),
              CircleAvatar(
                radius: SpacingConstants.avatarSize,
                backgroundColor: Colors.green[100],
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [Colors.white, Colors.green[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: SpacingConstants.largePadding,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 70),
          padding: const EdgeInsets.fromLTRB(
            SpacingConstants.mediumPadding,
            SpacingConstants.smallPadding,
            SpacingConstants.mediumPadding,
            SpacingConstants.smallPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ImagePickerButton(controller: controller),
              const SizedBox(width: SpacingConstants.smallPadding),
              _TextInputField(
                controller: controller,
                focusNode: focusNode,
                onSend: onSend,
              ),
              const SizedBox(width: SpacingConstants.smallPadding),
              _SendButton(controller: controller, onSend: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerButton extends StatelessWidget {
  final AiChatController controller;

  const _ImagePickerButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingConstants.smallPadding / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.grey[800]!, Colors.grey[700]!]
                  : [Colors.grey[100]!, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: SpacingConstants.mediumRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.add_photo_alternate_outlined,
          color: Theme.of(context).colorScheme.onSurface,
          size: SpacingConstants.iconSizeMedium,
        ),
        tooltip: 'send_image'.tr,
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
          );
          if (result != null && result.files.single.path != null) {
            final file = File(result.files.single.path!);
            final message = controller.inputController.text.trim();
            await controller.sendImageMessage(message, file);
            controller.inputController.clear();
            controller.inputText.value = '';
            HapticFeedback.lightImpact();
          }
        },
      ),
    );
  }
}

class _TextInputField extends StatefulWidget {
  final AiChatController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _TextInputField({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<_TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<_TextInputField> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppTextInputField(
        controller: widget.controller.inputController,
        focusNode: widget.focusNode,
        hint: 'type_your_message'.tr,
        maxLines: 2,
        keyboardType: TextInputType.multiline,
        validator: null,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final AiChatController controller;
  final VoidCallback onSend;

  const _SendButton({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final hasText =
          controller.inputText.value.trim().isNotEmpty; // Use inputText

      if (isLoading) {
        return Container(
          margin: const EdgeInsets.only(
            bottom: SpacingConstants.smallPadding / 2,
          ),
          padding: const EdgeInsets.all(SpacingConstants.mediumPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkMode
                      ? [Colors.grey[600]!, Colors.grey[500]!]
                      : [Colors.grey[400]!, Colors.grey[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: SpacingConstants.mediumRadius,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const SizedBox(
            width: SpacingConstants.iconSizeSmall,
            height: SpacingConstants.iconSizeSmall,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        );
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(
          bottom: SpacingConstants.smallPadding / 2,
        ),
        transform: Matrix4.identity()..scale(hasText ? 1.0 : 0.9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [Colors.green[600]!, Colors.green[500]!]
                    : [Colors.green[600]!, Colors.green[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow:
              hasText
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: SpacingConstants.largePadding,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: SpacingConstants.mediumRadius,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: SpacingConstants.iconSizeSmall,
          ),
          onPressed: hasText ? onSend : null,
          tooltip: 'send_message'.tr,
        ),
      );
    });
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value - delay).clamp(0.0, 1.0);
            final scale = (1 - (animationValue * 2 - 1).abs()).clamp(0.5, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConstants.smallPadding / 4,
              ),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
