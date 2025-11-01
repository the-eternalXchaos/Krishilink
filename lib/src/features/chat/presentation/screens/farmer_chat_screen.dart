import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/src/core/constants/api_constants.dart';
import 'package:krishi_link/src/features/auth/data/token_service.dart';
import 'package:krishi_link/src/features/chat/data/chat_cache_service.dart';
import 'package:krishi_link/src/features/chat/data/chat_services.dart';
import 'package:krishi_link/src/features/chat/data/live_chat_api_service.dart';
import 'package:krishi_link/src/features/chat/presentation/screens/live_chat_screen.dart';
import 'package:signalr_netcore/signalr_client.dart';

class FarmerChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  const FarmerChatScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<FarmerChatScreen> createState() => _FarmerChatScreenState();
}

class _FarmerChatScreenState extends State<FarmerChatScreen>
    with SingleTickerProviderStateMixin {
  late final LiveChatApiService _api;
  late final AuthController _auth;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool isLive = false;
  bool isConnecting = false;
  List<Map<String, dynamic>> customers = [];
  String? statusMessage;
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  Timer? _pollTimer;
  bool _isChatOpen = false;
  bool _isRefreshing = false;
  StreamSubscription<HubConnectionState>? _stateSub;
  String? _activeChatUserId;

  @override
  void initState() {
    super.initState();
    _api = LiveChatApiService();
    _auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());

    // Initialize glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _load();

    // Keep UI in sync with actual hub connection state
    _stateSub = ChatService.I.connectionState.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case HubConnectionState.Connected:
            isLive = true;
            isConnecting = false;
            statusMessage = 'connected_to_hub'.tr;
            break;
          case HubConnectionState.Connecting:
          case HubConnectionState.Reconnecting:
            isConnecting = true;
            statusMessage = 'connecting_to_hub'.tr;
            break;
          case HubConnectionState.Disconnecting:
            isConnecting = true;
            statusMessage = 'disconnecting_from_hub'.tr;
            break;
          case HubConnectionState.Disconnected:
            isLive = false;
            isConnecting = false;
            statusMessage = 'offline'.tr;
            break;
        }
      });
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    try {
      await _load();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _load() async {
    try {
      // Check farmer live status only if productId is provided and valid
      if (widget.productId.isNotEmpty) {
        debugPrint('📊 Checking live status for product: ${widget.productId}');
        try {
          isLive = await _api.isFarmerLive(widget.productId);
          debugPrint('📊 Farmer live status: $isLive');
        } catch (e) {
          debugPrint('❌ Failed to check live status: $e');
          isLive = false;
          // Don't show error for live status check failure
        }
      } else {
        debugPrint('⚠️ No productId provided, assuming not live');
        isLive = false;
      }

      // Try showing cached customers immediately for better UX
      final cachedCustomers = await ChatCacheService.I.loadCustomerList();
      if (cachedCustomers.isNotEmpty && mounted) {
        setState(() {
          customers = List<Map<String, dynamic>>.from(cachedCustomers);
        });
        debugPrint('📦 Loaded ${customers.length} customers from cache');
      }

      // Load customers with retry mechanism
      debugPrint('📋 Loading customers...');
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final partners = await _api.getMyCustomersForChat();
          customers =
              partners
                  .map(
                    (p) => {
                      'id': p['id'],
                      'name': p['name'],
                      'contact': p['contact'],
                    },
                  )
                  .toList();
          debugPrint('📋 Loaded ${customers.length} customers successfully');
          // Persist list and names for future sessions
          unawaited(ChatCacheService.I.saveCustomerList(customers));
          unawaited(
            ChatCacheService.I.upsertMany({
              for (final c in customers)
                if ((c['id'] ?? '').toString().isNotEmpty &&
                    (c['name'] ?? '').toString().isNotEmpty)
                  (c['id'] as String): (c['name'] as String),
            }),
          );
          break;
        } catch (e) {
          debugPrint('❌ Customer load attempt $attempt/3 failed: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt * 2));
          } else {
            // Last attempt failed, show error
            debugPrint('❌ All customer load attempts failed');
            if (mounted) {
              setState(() {
                statusMessage =
                    'Failed to load customer list. Please try refreshing.';
              });
            }
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      setState(() {
        statusMessage = 'Error loading chat data';
      });
    }
  }

  void _startInboxListener() {
    if (_msgSub != null) return;
    debugPrint('👂 Starting inbox listener');
    _msgSub = ChatService.I.messages.listen((raw) async {
      try {
        if (raw['system'] == true) return;
        final String? senderId = (raw['senderId'] as String?)?.trim();
        final String senderName =
            (raw['senderName'] as String?)?.trim() ?? 'Unknown';
        final String message = raw['message']?.toString() ?? '';
        final myId = _auth.userData?.id;

        debugPrint('📨 Inbox: id=$senderId, name=$senderName, msg=$message');

        if (senderId != null && senderId.isNotEmpty && senderId == myId) {
          debugPrint('⏭️ Ignoring self message');
          return;
        }

        String? effectiveId = senderId;
        if (effectiveId == null || effectiveId.isEmpty) {
          debugPrint('🔍 ID null, trying to match name: $senderName');
          final partners = await _api.getMyCustomersForChat();
          customers =
              partners
                  .map(
                    (p) => {
                      'id': p['id'],
                      'name': p['name'],
                      'contact': p['contact'],
                    },
                  )
                  .toList();
          final match = customers.firstWhere(
            (c) =>
                (c['name'] as String).toLowerCase() == senderName.toLowerCase(),
            orElse: () => {},
          );
          if (match.isNotEmpty && match['id'] != null) {
            effectiveId = match['id'] as String;
            debugPrint('✅ Matched ID: $effectiveId');
          } else {
            debugPrint('⚠️ No ID match; using placeholder');
          }
        }

        final keyId = effectiveId ?? 'unknown_${senderName.hashCode}';
        // Persist any known mapping to cache for nicer future display
        if ((effectiveId ?? '').isNotEmpty &&
            senderName.isNotEmpty &&
            senderName != 'Unknown') {
          await ChatCacheService.I.upsertName(keyId, senderName);
        }
        if (!mounted) return;

        // Compute updates outside setState when awaiting is needed
        final idx = customers.indexWhere((c) => c['id'] == keyId);
        String? cachedName;
        if (idx == -1) {
          cachedName = await ChatCacheService.I.getName(keyId);
        }

        setState(() {
          if (idx == -1) {
            customers.insert(0, {
              'id': keyId,
              'name':
                  (cachedName?.isNotEmpty == true)
                      ? cachedName
                      : (senderName.isNotEmpty
                          ? senderName
                          : ChatCacheService.I.prettyFallback(
                            keyId,
                            prefix: 'Buyer',
                          )),
              'contact': '',
              'unread': (!_isChatOpen || _activeChatUserId != keyId) ? 1 : 0,
            });
            debugPrint('➕ Added new customer: $keyId - $senderName');
          } else {
            final entry = customers.removeAt(idx);
            // If we learned a better name, update it
            if (senderName.isNotEmpty && senderName != 'Unknown') {
              entry['name'] = senderName;
            }
            // Increment unread if this isn\'t the active chat
            if (!_isChatOpen || _activeChatUserId != keyId) {
              final current =
                  int.tryParse((entry['unread'] ?? 0).toString()) ?? 0;
              entry['unread'] = current + 1;
            }
            customers.insert(0, entry);
            debugPrint('🔼 Moved $keyId to top');
          }
          debugPrint('📋 List updated: ${customers.length} customers');
        });

        // Persist updated list asynchronously
        unawaited(ChatCacheService.I.saveCustomerList(customers));

        // Notify farmer if chat view isn't open
        if (!_isChatOpen && mounted) {
          final preview =
              message.length > 60 ? '${message.substring(0, 57)}...' : message;
          Get.snackbar(
            'New message',
            '${senderName.isNotEmpty ? senderName : 'Buyer'}: $preview',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(12),
            borderRadius: 10,
          );
        }
      } catch (e) {
        debugPrint('❌ Inbox listener error: $e');
      }
    });
  }

  Future<void> _goOffline() async {
    debugPrint(
      '🔴 [_goOffline] invoked. Env(before): ${ChatService.I.envSummary()}',
    );
    if (!isLive && !isConnecting) return;
    setState(() {
      statusMessage = 'disconnecting_from_hub'.tr;
      isConnecting = true;
    });
    try {
      debugPrint('🔴 [_goOffline] calling ChatService.disconnect()');
      await ChatService.I.disconnect();
      debugPrint('🔴 [_goOffline] ChatService.disconnect() returned');
      _msgSub?.cancel();
      _msgSub = null;
      _pollTimer?.cancel();
      _pollTimer = null;
      if (!mounted) return;
      setState(() {
        isLive = false;
        isConnecting = false;
        statusMessage = 'offline'.tr;
      });
      Get.snackbar(
        'Offline',
        'You are now offline and will not receive live messages',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        colorText: Colors.orange[700],
      );
      debugPrint(
        '🔴 [_goOffline] completed. Env(after): ${ChatService.I.envSummary()}',
      );
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
      if (!mounted) return;
      setState(() {
        isConnecting = false;
        statusMessage = 'Failed to disconnect';
      });
    }
  }

  Future<void> _onPowerPressed() async {
    // Extra debug and user feedback when pressing the power button
    debugPrint(
      '🛑 [PowerButton] pressed. Env(before): ${ChatService.I.envSummary()}',
    );
    Get.snackbar(
      'Disconnecting',
      'Closing live connection to the hub…',
      backgroundColor: Colors.orange.withValues(alpha: 0.08),
      colorText: Colors.orange[700],
      duration: const Duration(seconds: 2),
    );
    await _goOffline();
    debugPrint(
      '🛑 [PowerButton] completed. Env(after): ${ChatService.I.envSummary()}',
    );
  }

  Future<void> _connectLive() async {
    if (isConnecting) return;
    setState(() {
      isConnecting = true;
      statusMessage = 'connecting_to_hub'.tr;
    });

    try {
      if (await TokenService.isTokenExpired()) {
        debugPrint('🔐 Token expired, refreshing');
        await TokenService.refreshAccessToken();
        await _auth.checkLogin();
      }

      final token =
          await TokenService.getAccessToken() ?? _auth.userData?.token ?? '';
      debugPrint('🔐 Token length: ${token.length}');

      if (token.isEmpty) {
        debugPrint('❌ No valid token');
        setState(() {
          statusMessage = 'authentication_error_login_again'.tr;
          isConnecting = false;
        });
        Get.snackbar(
          'auth_error'.tr,
          'login_again'.tr,
          backgroundColor: Colors.red.withValues(alpha: 0.5),
          colorText: Colors.red[700],
        );
        return;
      }

      var ok = await ChatService.I.connect(
        hubUrl: '${ApiConstants.baseUrl}/ChatHub',
        verbose: true,
      );

      if (!ok) {
        debugPrint('🌐 Retrying lowercase: ${ApiConstants.baseUrl}/chatHub');
        ok = await ChatService.I.connect(
          hubUrl: '${ApiConstants.baseUrl}/chatHub',
          verbose: true,
        );
      }

      if (!ok) {
        final diagnostics = await _runDiagnostics();
        debugPrint('🔧 Diagnostics: $diagnostics');
        setState(() {
          statusMessage = 'failed_to_connect_to_hub'.tr;
          isConnecting = false;
        });
        Get.snackbar(
          'connection_failed'.tr,
          'could_not_connect_to_hub'.tr,
          backgroundColor: Colors.white.withValues(alpha: 1),
          colorText: Colors.black,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      debugPrint('✅ Connected to hub');
      setState(() {
        isLive = true;
        statusMessage = 'connected_to_hub'.tr;
        isConnecting = false;
      });
      _startInboxListener();

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (!mounted || !isLive) {
          timer.cancel();
          return;
        }
        await _load();
        debugPrint('🔄 Polled customers: ${customers.length}');
      });

      await _load();
      Get.snackbar(
        'Live',
        'You are now live and can receive messages',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green[700],
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            statusMessage = null;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      setState(() {
        statusMessage = 'Connection error occurred';
        isConnecting = false;
      });
      Get.snackbar(
        'Error',
        'An error occurred while connecting',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red[700],
      );
    }
  }

  Future<String> _runDiagnostics() async {
    try {
      final token = _auth.userData?.token ?? '';
      final tokenPreview =
          token.length > 16
              ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
              : token;
      debugPrint('🔧 === DIAGNOSTICS ===');
      debugPrint('🔧 Token length: ${token.length}');
      debugPrint('🔧 Token preview: $tokenPreview');
      debugPrint('🔧 Last error: ${ChatService.I.lastError}');
      debugPrint('🔧 Environment: ${ChatService.I.envSummary()}');
      debugPrint('🔧 Snapshot: ${ChatService.I.snapshot()}');
      debugPrint('🔧 === END DIAGNOSTICS ===');
      return 'Token: ${token.length} chars, LastError: ${ChatService.I.lastError ?? 'none'}';
    } catch (e) {
      debugPrint('🔧 Diagnostics failed: $e');
      return 'Diagnostics failed: $e';
    }
  }

  void _openChat() {
    debugPrint('💬 Opening general chat for product: ${widget.productName}');
    _isChatOpen = true;
    Get.to(
      () => LiveChatScreen(
        productId: widget.productId,
        productName: widget.productName,
        farmerName: 'Me',
        emailOrPhone: '',
      ),
    )?.then((_) {
      _isChatOpen = false;
      if (mounted) {
        // Force immediate UI refresh so AppBar actions redraw with latest state
        setState(() {});
      }
      _load();
    });
  }

  void _openCustomerChat(Map<String, dynamic> customer) {
    debugPrint('💬 Opening chat with customer: ${customer['name']}');
    _isChatOpen = true;
    _activeChatUserId = (customer['id'] ?? '').toString();
    // Clear unread immediately on open
    final idx = customers.indexWhere((c) => c['id'] == _activeChatUserId);
    if (idx != -1) {
      setState(() {
        customers[idx]['unread'] = 0;
      });
      unawaited(ChatCacheService.I.saveCustomerList(customers));
    }
    Get.to(
      () => LiveChatScreen(
        productId: widget.productId,
        productName: widget.productName,
        farmerName: customer['name'],
        emailOrPhone: customer['contact'],
        receiverUserId: customer['id'],
      ),
    )?.then((_) {
      _isChatOpen = false;
      // Ensure unread cleared when returning
      if (_activeChatUserId != null) {
        final idx = customers.indexWhere((c) => c['id'] == _activeChatUserId);
        if (idx != -1) {
          setState(() {
            customers[idx]['unread'] = 0;
          });
          unawaited(ChatCacheService.I.saveCustomerList(customers));
        }
      }
      _activeChatUserId = null;
      if (mounted) {
        // Force immediate UI refresh so AppBar actions redraw with latest state
        setState(() {});
      }
      _load();
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _glowController.dispose();
    _msgSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats${widget.productName.isNotEmpty ? ' - ${widget.productName}' : ''}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow:
                      isLive
                          ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(
                                0.5 * _glowAnimation.value,
                              ),
                              blurRadius: 12 * _glowAnimation.value,
                              spreadRadius: 2 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: Colors.red.withOpacity(
                                0.2 * _glowAnimation.value,
                              ),
                              blurRadius: 18 * _glowAnimation.value,
                              spreadRadius: 3 * _glowAnimation.value,
                            ),
                          ]
                          : [],
                ),
                child: IconButton(
                  tooltip:
                      isLive
                          ? 'Disconnect from Hub'
                          : (isConnecting
                              ? 'Connecting...'
                              : 'Offline (Use Go Live to connect)'),
                  onPressed: (isConnecting || !isLive) ? null : _onPowerPressed,
                  icon: Icon(
                    Icons.power_settings_new,
                    color: isLive ? Colors.red : Colors.red.withOpacity(0.4),
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed:
                  isLive || isConnecting
                      ? (isLive ? _openChat : null)
                      : _connectLive,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon:
                  isConnecting
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        isLive ? Icons.chat : Icons.wifi_tethering,
                        size: 18,
                      ),
              label: Text(
                isLive
                    ? 'open_chat'.tr
                    : isConnecting
                    ? 'connecting_to_hub'.tr
                    : 'go_live'.tr,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLive || isConnecting || statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isLive
                        ? Colors.green.withValues(alpha: 0.1)
                        : isConnecting
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLive)
                    const Icon(Icons.circle, size: 12, color: Colors.green)
                  else if (isConnecting)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      statusMessage ??
                          (isLive
                              ? 'You are live and ready to receive messages'
                              : isConnecting
                              ? 'Connecting to chat hub...'
                              : ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            isLive
                                ? Colors.green[700]
                                : isConnecting
                                ? Colors.blue[700]
                                : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child:
                  customers.isEmpty
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 64),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_customers_yet'.tr,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isLive
                                      ? 'youre_live_message'.tr
                                      : 'go_live_to_receive'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (_, i) {
                          final customer = customers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              customer['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(customer['contact']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((int.tryParse(
                                          (customer['unread'] ?? 0).toString(),
                                        ) ??
                                        0) >
                                    0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (customer['unread'] ?? 0).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () => _openCustomerChat(customer),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
