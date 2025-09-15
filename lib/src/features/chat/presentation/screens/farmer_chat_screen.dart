import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krishi_link/src/features/chat/data/live_chat_api_service.dart';
import 'package:krishi_link/src/features/chat/presentation/screens/live_chat_screen.dart';
import 'package:krishi_link/src/features/chat/data/chat_services.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/token_service.dart';

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

class _FarmerChatScreenState extends State<FarmerChatScreen> {
  late final LiveChatApiService _api;
  late final AuthController _auth;
  bool isLive = false;
  bool isConnecting = false;
  List<Map<String, dynamic>> customers = [];
  String? statusMessage;
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _api = LiveChatApiService();
    _auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    _load();
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
        if (!mounted) return;

        setState(() {
          final idx = customers.indexWhere((c) => c['id'] == keyId);
          if (idx == -1) {
            customers.insert(0, {
              'id': keyId,
              'name': senderName.isNotEmpty ? senderName : 'Unknown Buyer',
              'contact': '',
            });
            debugPrint('➕ Added new customer: $keyId - $senderName');
          } else {
            final entry = customers.removeAt(idx);
            customers.insert(0, entry);
            debugPrint('🔼 Moved $keyId to top');
          }
          debugPrint('📋 List updated: ${customers.length} customers');
        });
      } catch (e) {
        debugPrint('❌ Inbox listener error: $e');
      }
    });
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
    Get.to(
      () => LiveChatScreen(
        productId: widget.productId,
        productName: widget.productName,
        farmerName: 'Me',
        emailOrPhone: '',
      ),
    )?.then((_) => _load());
  }

  void _openCustomerChat(Map<String, dynamic> customer) {
    debugPrint('💬 Opening chat with customer: ${customer['name']}');
    Get.to(
      () => LiveChatScreen(
        productId: widget.productId,
        productName: widget.productName,
        farmerName: customer['name'],
        emailOrPhone: customer['contact'],
        receiverUserId: customer['id'],
      ),
    )?.then((_) => _load());
  }

  @override
  void dispose() {
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
            child:
                customers.isEmpty
                    ? Center(
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLive
                                ? 'youre_live_message'.tr
                                : 'go_live_to_receive'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(customer['contact']),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _openCustomerChat(customer),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
