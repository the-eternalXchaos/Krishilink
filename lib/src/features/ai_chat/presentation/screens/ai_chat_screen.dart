import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:krishi_link/core/lottie/lottie_widget.dart';
import 'package:krishi_link/core/lottie/popup_service.dart';
import 'package:krishi_link/features/chat/widgets/typing_indicator.dart';
import 'package:krishi_link/src/core/components/confirm%20box/custom_confirm_dialog.dart';
import 'package:krishi_link/src/core/components/custom_drawer/custom_drawer.dart';
import 'package:krishi_link/src/core/components/material_ui/pop_up.dart';
import 'package:krishi_link/src/core/constants/lottie_assets.dart';
import 'package:krishi_link/src/features/ai_chat/presentation/controllers/ai_chat_controller.dart';

class AiChatScreen extends StatefulWidget {
  final String name;
  const AiChatScreen({super.key, required this.name});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final FocusNode _textFieldFocusNode;
  Timer? _debounceTimer;
  late final AiChatController controller;
  // AuthController not needed in this screen; removed unused field.

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
      controller.loadAiChats();
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

  // -------- Drawer items builder (reactive) --------
  List<DrawerItem> _chatHistoryItems(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <DrawerItem>[];

    // Header + quick actions
    items.add(DrawerItem.section('chat_history'.tr));
    items.add(
      DrawerItem.item(
        title: 'new_chat'.tr,
        icon: Icons.add_circle_outline,
        onTap: () {
          controller.clearChat();
          controller.selectedChatId.value = '';
          Navigator.of(context).maybePop();
          controller.scrollToBottom();
          PopupService.showSnackbar(
            type: PopupType.info,
            title: 'new_chat'.tr,
            message: 'start_typing_to_begin'.tr,
          );
        },
      ),
    );
    items.add(
      DrawerItem.item(
        title: 'refresh'.tr,
        icon: Icons.refresh,
        onTap: () async => controller.loadAiChats(),
        isDense: true,
      ),
    );
    items.add(DrawerItem.divider());

    // --- Build the groups AFTER we inspect aiChats ---
    final now = DateTime.now();
    final todayChats = <DrawerItem>[];
    final yesterdayChats = <DrawerItem>[];
    final olderChats = <DrawerItem>[];

    for (final m in controller.aiChats) {
      final id = (m['id'] ?? '').toString();
      final title = (m['title'] ?? 'Conversation').toString();
      final preview = (m['preview'] ?? '').toString();
      final ts = m['timestamp'] as DateTime?;
      final timeStr =
          ts == null
              ? ''
              : '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

      final chatItem = DrawerItem.item(
        title: title,
        subtitle: preview.isEmpty ? null : preview,
        icon: Icons.forum_outlined,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: .6),
                ),
              ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'delete_chat'.tr,
              splashRadius: 18,
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => CustomConfirmDialog(
                        title: 'delete_chat'.tr,
                        content: 'Are you sure you want to delete “$title”?',
                        confirmText: 'yes'.tr,
                        cancelText: 'no'.tr,
                        onConfirm: () async {
                          Get.back();
                          final ok = await controller.deleteChat(id);
                          if (ok) {
                            PopupService.showSnackbar(
                              type: PopupType.success,
                              title: 'success'.tr,
                              message: 'conversation_removed'.tr,
                            );
                          } else {
                            PopupService.showSnackbar(
                              type: PopupType.error,
                              title: 'failed'.tr,
                              message: 'could_not_delete_conversation'.tr,
                            );
                          }
                        },
                        onCancel: () => Get.back(),
                      ),
                );
              },
            ),
          ],
        ),
        onTap: () async {
          await controller.openChat(id);
          Navigator.of(context).maybePop();
          controller.scrollToBottom();
        },
      );

      if (ts == null) {
        olderChats.add(chatItem);
      } else if (ts.year == now.year &&
          ts.month == now.month &&
          ts.day == now.day) {
        todayChats.add(chatItem);
      } else {
        final y = now.subtract(const Duration(days: 1));
        if (ts.year == y.year && ts.month == y.month && ts.day == y.day) {
          yesterdayChats.add(chatItem);
        } else {
          olderChats.add(chatItem);
        }
      }
    }

    // --- FLAT SECTIONS (no subItems) ---
    if (todayChats.isNotEmpty) {
      items.add(DrawerItem.section('Today'));
      items.addAll(todayChats);
    }
    if (yesterdayChats.isNotEmpty) {
      items.add(DrawerItem.divider());
      items.add(DrawerItem.section('Yesterday'));
      items.addAll(yesterdayChats);
    }
    if (olderChats.isNotEmpty) {
      items.add(DrawerItem.divider());
      items.add(DrawerItem.section('Older'));
      items.addAll(olderChats);
    }

    if (items.length <= 4) {
      items.add(
        DrawerItem.item(
          title: 'No history yet',
          icon: Icons.inbox_outlined,
          enabled: false,
          isDense: true,
        ),
      );
    }

    return items;
  }

  // Custom header for the drawer
  Widget _buildCustomHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                    child: LottieWidget(path: LottieAssets.aiLogo, height: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'KrishiLink AI',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    semanticsLabel: 'KrishiLink AI',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to open, swipe to delete',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.7),
                ),
                semanticsLabel: 'Tap to open, swipe to delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (controller.isLoading.value) return;
    if (controller.inputController.text.trim().isNotEmpty) {
      controller.sendMessage();
      HapticFeedback.lightImpact();
      Future.microtask(controller.scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,

      // floatingActionButton: Obx(() {
      //   if (controller.isAtBottom.value) return const SizedBox.shrink();
      //   return FloatingActionButton(
      //     heroTag: "scroll_down",
      //     mini: true,
      //     shape: const CircleBorder(),
      //     backgroundColor: Theme.of(context).colorScheme.primary,
      //     foregroundColor: Colors.white,
      //     onPressed: controller.scrollToBottom,
      //     child: const Icon(Icons.arrow_downward),
      //   );
      // }),

      // Updated CustomDrawer usage
      drawer: Obx(() {
        final items = _chatHistoryItems(context);
        return CustomDrawer(
          width: 340,
          customHeader: _buildCustomHeader(context),
          menuItems: items,
          showDividers: true,
          footer: _DrawerFooter(controller: controller),
          footerPadding: const EdgeInsets.all(16),
          animationDuration: const Duration(milliseconds: 250),
          itemTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
          ),
          itemIconColor: cs.onSurfaceVariant,
          dividerColor: cs.outlineVariant,
        );
      }),

      body: Stack(
        children: [
          Column(
            children: [
              _AppBar(
                userName: widget.name,
                showSideBar: () => _scaffoldKey.currentState?.openDrawer(),
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

          //   CROLLD WON BUTTON FRO IT , ADN PUR LIST IN REVERSE ORDER ,
          Obx(() {
            if (controller.isAtBottom.value) return const SizedBox.shrink();
            return Positioned(
              bottom: 80,
              left: (Get.width) / 2, // 170

              child: FloatingActionButton(
                heroTag: "scroll_down",
                mini: true,
                shape: const CircleBorder(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                onPressed: controller.scrollToBottom,
                child: const Icon(Icons.arrow_downward),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final String userName;
  final VoidCallback showSideBar;

  const _AppBar({required this.userName, required this.showSideBar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: .90)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.1),
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
                        color: cs.onPrimary.withValues(alpha: 0.2),
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
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.menu,
                  color: theme.appBarTheme.foregroundColor ?? cs.onPrimary,
                  size: 24,
                ),
                tooltip: 'Side bar',
                onPressed: showSideBar,
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
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.shadow.withValues(alpha: 0.1),
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
                color: cs.onSurface.withValues(alpha: 0.65),
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
          questions.map((q) {
            return InkWell(
              onTap: () {
                controller.inputController.text = q;
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
                  q,
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
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [SizedBox(width: 8), TypingIndicator()],
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
                        color: cs.shadow.withValues(alpha: 0.05),
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
                              color: cs.onPrimary.withValues(alpha: 0.9),
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
                                      ? cs.onPrimary.withValues(alpha: 0.7)
                                      : cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      if (message['error'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final isBusy = controller.isLoading.value;
            return Row(
              children: [
                // Optional: keep image picker to the left
                const _ImagePickerButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.inputController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'type_your_message'.tr,
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
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => isBusy ? null : onSend(),
                    onChanged: (v) => controller.inputText.value = v,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'ai_send_btn',
                  onPressed: isBusy ? null : onSend,
                  backgroundColor: cs.primary,
                  child:
                      isBusy
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
            );
          }),
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
          color: cs.onSurface.withValues(alpha: 0.65),
          size: 24,
        ),
        tooltip: 'send_image'.tr,
        onPressed: () {
          final cs2 = Theme.of(context).colorScheme;
          Get.snackbar(
            'Coming Soon',
            'Image upload is an upcoming feature. For now, please send text only.',
            backgroundColor: cs2.tertiaryContainer,
            colorText: cs2.onTertiaryContainer,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            icon: Icon(Icons.info_outline, color: cs2.tertiary),
          );
        },
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  final AiChatController controller;
  const _DrawerFooter({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant, width: .5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      controller.userName!.isNotEmpty
                          ? controller.userName![0].toUpperCase()
                          : 'U',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.primary,
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
                          controller.userName.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'User',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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
