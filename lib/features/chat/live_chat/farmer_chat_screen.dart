// lib/features/farmer/screens/farmer_chats_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:krishi_link/features/chat/live_chat/live_chat_api_service.dart';
import 'package:krishi_link/features/chat/live_chat/live_chat_screen.dart';
import 'package:krishi_link/features/chat/live_chat/chat_services.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:krishi_link/services/token_service.dart';

class FarmerChatScreen extends StatefulWidget {
  final String productId; // choose which product to be live for
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
  StreamSubscription<Map<String, dynamic>>? _msgSub; // live inbox listener

  @override
  void initState() {
    super.initState();
    // Use the central ApiService's Dio so auth interceptors
    final apiService =
        Get.isRegistered<ApiService>()
            ? Get.find<ApiService>()
            : Get.put(ApiService());
    _api = LiveChatApiService(apiService.dio);
    _auth =
        Get.isRegistered<AuthController>()
            ? Get.find<AuthController>()
            : Get.put(AuthController());
    _load();
  }

  Future<void> _load() async {
    try {
      isLive =
          widget.productId.isEmpty
              ? false
              : await _api.isFarmerLive(widget.productId);
      final partners = await _api.getMyCustomersForChat();
      customers =
          partners
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.displayName,
                  'contact': p.contact,
                },
              )
              .toList();

      // Log status to debug console
      debugPrint(
        '📱 Farmer Chat Screen loaded - Live: $isLive, Customers: ${customers.length}',
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading farmer chat data: $e');
      setState(() {
        statusMessage = 'Error loading chat data';
      });
    }
  }

  void _startInboxListener() {
    if (_msgSub != null) return; // already listening
    _msgSub = ChatRealtimeService.I.messages.listen((raw) {
      try {
        if (raw['system'] == true) return; // ignore system messages
        final senderId = (raw['senderId'] as String?)?.trim();
        final senderName = ((raw['senderName'] as String?) ?? '').trim();
        if (senderId == null || senderId.isEmpty) return;
        final myId = _auth.userData?.id;
        if (senderId == myId) return; // ignore self

        final idx = customers.indexWhere((c) => c['id'] == senderId);
        if (idx == -1) {
          if (!mounted) return;
          setState(() {
            customers.insert(0, {
              'id': senderId,
              'name': senderName.isNotEmpty ? senderName : 'Customer',
              'contact': '',
            });
          });
        } else {
          if (!mounted) return;
          setState(() {
            final entry = customers.removeAt(idx);
            customers.insert(0, entry);
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _connectLive() async {
    if (isConnecting) return;
    setState(() {
      isConnecting = true;
      statusMessage = 'connecting_to_hub'.tr;
    });

    try {
      debugPrint('🔐 Starting connection to chat hub...');

      // Ensure token available
      if (await TokenService.isTokenExpired()) {
        debugPrint('🔐 Token expired, refreshing...');
        await TokenService.refreshAccessToken();
        await _auth.checkLogin();
      }

      var token =
          await TokenService.getAccessToken() ?? _auth.userData?.token ?? '';
      debugPrint('🔐 Token length: ${token.length}');

      if (token.isEmpty) {
        debugPrint('❌ No valid token available');
        setState(() {
          statusMessage = 'authentication_error_login_again'.tr;
          isConnecting = false;
        });
        Get.snackbar(
          'auth_error'.tr,
          'login_again'.tr,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red[700],
        );
        return;
      }

      // Try connecting with capitalized path first
      debugPrint('🌐 Attempting connection to ${ApiConstants.baseUrl}/ChatHub');
      var ok = await ChatRealtimeService.I.connect(
        tokenProvider: () async {
          if (await TokenService.isTokenExpired()) {
            await TokenService.refreshAccessToken();
            await _auth.checkLogin();
          }
          return await TokenService.getAccessToken() ??
              _auth.userData?.token ??
              '';
        },
        hubUrl: '${ApiConstants.baseUrl}/ChatHub',
      );

      // Try lowercase path if first attempt fails
      if (!ok) {
        debugPrint(
          '🌐 Retrying with lowercase path: ${ApiConstants.baseUrl}/chatHub',
        );
        ok = await ChatRealtimeService.I.connect(
          tokenProvider: () async {
            if (await TokenService.isTokenExpired()) {
              await TokenService.refreshAccessToken();
              await _auth.checkLogin();
            }
            return await TokenService.getAccessToken() ??
                _auth.userData?.token ??
                '';
          },
          hubUrl: '${ApiConstants.baseUrl}/chatHub',
        );
      }

      if (!ok) {
        final err = ChatRealtimeService.I.lastError;
        debugPrint('❌ Connection failed: $err');

        // Log detailed diagnostics to console
        final diagnostics = await _runDiagnostics();
        debugPrint('🔧 Connection diagnostics: $diagnostics');

        setState(() {
          statusMessage = 'failed_to_connect_to_hub'.tr;
          isConnecting = false;
        });

        Get.snackbar(
          'connection_failed'.tr,
          'could_not_connect_to_hub'.tr,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red[700],
          duration: const Duration(seconds: 4),
        );
        return;
      }

      debugPrint('✅ Successfully connected to chat hub');
      if (mounted) {
        setState(() {
          isLive = true;
          statusMessage = 'connected_to_hub'.tr;
          isConnecting = false;
        });
      }
      _startInboxListener();
      await _load();
      Get.snackbar(
        'Live',
        'You are now live and can receive messages',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green[700],
      );

      // Clear success message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            statusMessage = null;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Exception during connection: $e');
      setState(() {
        statusMessage = 'Connection error occurred';
        isConnecting = false;
      });
      Get.snackbar(
        'Error',
        'An error occurred while connecting',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red[700],
      );
    }
  }

  // Run diagnostics silently in background and return summary
  Future<String> _runDiagnostics() async {
    try {
      final token = _auth.userData?.token ?? '';
      final tokenPreview =
          token.length > 16
              ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
              : token;
      final probe = await ChatRealtimeService.I.negotiateProbe(
        '${ApiConstants.baseUrl}/ChatHub',
      );

      // Log all diagnostics to console
      debugPrint('🔧 === DIAGNOSTICS ===');
      debugPrint('🔧 Token length: ${token.length}');
      debugPrint('🔧 Token preview: $tokenPreview');
      debugPrint('🔧 Probe result: ${probe ?? 'failed'}');
      debugPrint('🔧 Last error: ${ChatRealtimeService.I.lastError}');
      debugPrint('🔧 Environment: ${ChatRealtimeService.I.envSummary()}');
      debugPrint('🔧 Connection snapshot: ${ChatRealtimeService.I.snapshot()}');
      debugPrint('🔧 === END DIAGNOSTICS ===');

      return 'Token: ${token.length} chars, Probe: ${probe ?? 'failed'}';
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
          // Status indicator
          if (isLive || isConnecting || statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isLive
                        ? Colors.green.withOpacity(0.1)
                        : isConnecting
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
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

          // Customer list
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
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_customers_yet'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLive
                                ? 'youre_live_message'.tr
                                : 'go_live_to_receive'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
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
                                .withOpacity(0.1),
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

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }
}
