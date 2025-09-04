// lib/features/farmer/screens/farmer_chats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:krishi_link/features/chat/live_chat/live_chat_api_service.dart';
import 'package:krishi_link/features/chat/live_chat/live_chat_screen.dart';
import 'package:krishi_link/features/chat/live_chat/chat_services.dart';
import 'package:krishi_link/features/auth/controller/auth_controller.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/api_services/api_service.dart';
import 'package:flutter/services.dart';
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
  bool showLogs = false;
  List<Map<String, dynamic>> customers = [];
  String? diagnosticsResult;
  String? _tokenSummary; // displayed in diagnosticsResult panel
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    // Use the central ApiService's Dio so auth interceptors attach the JWT.
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
    isLive =
        widget.productId.isEmpty
            ? false
            : await _api.isFarmerLive(widget.productId);
    final partners = await _api.getMyCustomersForChat();
    customers =
        partners
            .map(
              (p) => {'id': p.id, 'name': p.displayName, 'contact': p.contact},
            )
            .toList();
    if (mounted) setState(() {});
  }

  Future<void> _connectLive() async {
    if (isConnecting) return;
    setState(() => isConnecting = true);
    try {
      // Ensure token available
      // Ensure fresh token (refresh if expired)
      if (await TokenService.isTokenExpired()) {
        await TokenService.refreshAccessToken();
        await _auth.checkLogin();
      }
      var token =
          await TokenService.getAccessToken() ?? _auth.userData?.token ?? '';
      debugPrint('🔐 Connecting to hub (token length=${token.length})');
      if (token.isEmpty) {
        Get.snackbar('Auth Error', 'No valid token. Login again.');
        return;
      }

      var ok = await ChatRealtimeService.I.connect(
        tokenProvider: () async {
          // On each attempt re-check & refresh if needed
          if (await TokenService.isTokenExpired()) {
            await TokenService.refreshAccessToken();
            await _auth.checkLogin();
          }
          return await TokenService.getAccessToken() ??
              _auth.userData?.token ??
              '';
        },
        hubUrl: '${ApiConstants.baseUrl}/ChatHub', // try capitalized path first
      );
      if (!ok) {
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
        Get.snackbar(
          'Connection Failed',
          'Could not connect to hub${err != null ? ': $err' : ''}',
          duration: const Duration(seconds: 6),
        );

        setState(() => showLogs = true);
        return;
      }
      if (mounted) setState(() => isLive = true);
      await _load();
      Get.snackbar('Live', 'You are now live and can receive messages');
    } finally {
      if (mounted) setState(() => isConnecting = false);
    }
  }

  Future<void> _runDiagnostics() async {
    final token = _auth.userData?.token ?? '';
    final tokenPreview =
        token.length > 16
            ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
            : token;
    final probe = await ChatRealtimeService.I.negotiateProbe(
      '${ApiConstants.baseUrl}/ChatHub',
    );
    setState(() {
      diagnosticsResult =
          'Token len=${token.length} preview=$tokenPreview\nProbe: ${probe ?? 'failed'}\nLastErr: ${ChatRealtimeService.I.lastError}';
      showLogs = true;
    });
    Get.snackbar(
      'Diagnostics',
      'Check debug panel for details',
      duration: const Duration(seconds: 4),
    );
  }

  void _openChat() {
    Get.to(
      () => LiveChatScreen(
        productId: widget.productId,
        productName: widget.productName,
        farmerName: 'Me',
        emailOrPhone: '',
      ),
    )?.then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats (${widget.productName.isEmpty ? 'My Customers' : widget.productName})',
        ),
        actions: [
          IconButton(
            tooltip: 'Run diagnostics',
            icon: const Icon(Icons.health_and_safety_outlined),
            onPressed: _runDiagnostics,
          ),
          TextButton.icon(
            onPressed:
                isLive || isConnecting
                    ? (isLive ? _openChat : null)
                    : _connectLive,
            icon:
                isConnecting
                    ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.wifi_tethering, size: 18),
            label: Text(
              isLive
                  ? 'Open Chat'
                  : isConnecting
                  ? 'Connecting...'
                  : 'Go Live',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug toggle
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Toggle debug logs',
              icon: Icon(
                showLogs ? Icons.bug_report : Icons.bug_report_outlined,
              ),
              onPressed: () => setState(() => showLogs = !showLogs),
            ),
          ),
          if (isLive)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle, size: 10, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('You are live', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          if (!isLive && isConnecting)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connecting to hub...',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (showLogs)
            Container(
              height: 140,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          onPressed: () {
                            final snap = ChatRealtimeService.I.snapshot();
                            setState(() {
                              diagnosticsResult = 'SNAP: ' + snap.toString();
                            });
                          },
                          child: const Text(
                            'Snapshot',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final env = ChatRealtimeService.I.envSummary();
                            setState(() {
                              diagnosticsResult = 'ENV: ' + env.toString();
                            });
                          },
                          child: const Text(
                            'Env',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: ChatRealtimeService.I.exportLogs(),
                              ),
                            );
                            Get.snackbar(
                              'Logs',
                              'Copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          child: const Text(
                            'Copy Logs',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ChatRealtimeService.I.clearLogs();
                            setState(() {});
                          },
                          child: const Text(
                            'Clear Logs',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final list = await ChatRealtimeService.I.fullProbe(
                              hubUrl: '${ApiConstants.baseUrl}/chatHub',
                              tokenProvider:
                                  () async =>
                                      await TokenService.getAccessToken() ?? '',
                            );
                            setState(() {
                              diagnosticsResult =
                                  'FullProbe:\n' + list.join('\n');
                            });
                          },
                          child: const Text(
                            'FullProbe',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Quick manual diagnostics without full connection attempt
                            debugPrint('🔧 Manual Quick Diagnostics Started');
                            try {
                              final hubUrl = '${ApiConstants.baseUrl}/chatHub';
                              final token =
                                  await TokenService.getAccessToken() ?? '';

                              debugPrint('🔧 Testing hub URL: $hubUrl');
                              debugPrint('🔧 Token length: ${token.length}');
                              debugPrint(
                                '🔧 Token summary: ${ChatRealtimeService.I.summarizeToken(token)}',
                              );

                              // Test basic connectivity
                              final env = ChatRealtimeService.I.envSummary();
                              debugPrint('🔧 Environment: $env');

                              // Test negotiate endpoint
                              final probe = await ChatRealtimeService.I
                                  .negotiateProbe(hubUrl);
                              debugPrint(
                                '🔧 Negotiate probe: ${probe ?? "failed"}',
                              );

                              // Test auth negotiate
                              final authProbe = await ChatRealtimeService.I
                                  .negotiateAuthProbe(
                                    hubUrl: hubUrl,
                                    tokenProvider: () async => token,
                                  );
                              debugPrint(
                                '🔧 Auth negotiate probe: ${authProbe ?? "failed"}',
                              );

                              debugPrint(
                                '🔧 Manual Quick Diagnostics Completed',
                              );
                            } catch (e) {
                              debugPrint('🔧 Manual diagnostics failed: $e');
                            }
                          },
                          child: const Text(
                            'QuickTest',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              debugPrint(
                                '⚡ Starting FastTest - Short timeout connection test',
                              );
                              final result = await ChatRealtimeService.I.connect(
                                tokenProvider:
                                    () async =>
                                        await TokenService.getAccessToken() ??
                                        '',
                                serverTimeoutMs: 10000, // Only 10 seconds
                                keepAliveIntervalMs: 5000, // 5 seconds
                                verbose: true,
                                logFinalEnvOnFail: true,
                                preflightDiagnostics:
                                    false, // Skip preflight for speed
                              );
                              debugPrint('⚡ FastTest result: $result');
                              if (result) {
                                debugPrint(
                                  '⚡ FastTest SUCCESS - Connection works with short timeout!',
                                );
                                await ChatRealtimeService.I.disconnect();
                              } else {
                                debugPrint(
                                  '⚡ FastTest FAILED - Even short timeout fails',
                                );
                              }
                            } catch (e) {
                              debugPrint('⚡ FastTest ERROR: $e');
                            }
                          },
                          child: const Text(
                            'FastTest',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              debugPrint(
                                '📺 Starting SSE Test - Server-Sent Events connection test',
                              );
                              final result = await ChatRealtimeService.I
                                  .connectWithServerSentEvents(
                                    tokenProvider:
                                        () async =>
                                            await TokenService.getAccessToken() ??
                                            '',
                                    serverTimeoutMs: 15000, // 15 seconds
                                    keepAliveIntervalMs: 10000, // 10 seconds
                                  );
                              debugPrint('📺 SSE Test result: $result');
                              if (result) {
                                debugPrint(
                                  '📺 SSE Test SUCCESS - Server-Sent Events works!',
                                );
                                await ChatRealtimeService.I.disconnect();
                              } else {
                                debugPrint(
                                  '📺 SSE Test FAILED - Server-Sent Events also fails',
                                );
                              }
                            } catch (e) {
                              debugPrint('📺 SSE Test ERROR: $e');
                            }
                          },
                          child: const Text(
                            'SSE Test',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              debugPrint('🏥 Starting Server Health Check');
                              final health =
                                  await ChatRealtimeService.I
                                      .serverHealthCheck();
                              debugPrint('🏥 Health Check Results:');
                              health.forEach((key, value) {
                                debugPrint('🏥   $key: $value');
                              });

                              // Show if server APIs are working
                              final chatAPI =
                                  health['chatAPI']?.toString() ?? 'unknown';
                              if (chatAPI.contains('500')) {
                                debugPrint(
                                  '⚠️  WARNING: Chat API returning 500 errors - server issue detected',
                                );
                              } else if (chatAPI.contains('200')) {
                                debugPrint('✅ Chat API appears healthy');
                              }
                            } catch (e) {
                              debugPrint('🏥 Health Check ERROR: $e');
                            }
                          },
                          child: const Text(
                            'Health',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              debugPrint('🔐 Starting Token Debug Check');
                              final tokenDebug = await ChatRealtimeService.I.tokenDebugCheck();
                              debugPrint('🔐 Token Debug Results:');
                              tokenDebug.forEach((key, value) {
                                debugPrint('🔐   $key: $value');
                              });
                              
                              // Highlight critical issues
                              if (tokenDebug['TokenService.getAccessToken']?.toString().contains('NULL') == true) {
                                debugPrint('🔴 CRITICAL: No access token found!');
                              }
                              if (tokenDebug['tokenExpired']?.toString().contains('EXPIRED') == true) {
                                debugPrint('🔴 CRITICAL: Token is expired!');
                              }
                              if (tokenDebug['tokensMatch']?.toString().contains('NO') == true) {
                                debugPrint('🔴 CRITICAL: Token mismatch between methods!');
                              }
                            } catch (e) {
                              debugPrint('🔐 Token Debug ERROR: $e');
                            }
                          },
                          child: const Text('Token', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () async {
                            final probe = await ChatRealtimeService.I
                                .negotiateProbe(
                                  '${ApiConstants.baseUrl}/chatHub',
                                );
                            setState(() {
                              diagnosticsResult =
                                  'Probe: ' + (probe ?? 'failed');
                            });
                          },
                          child: const Text(
                            'Probe',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final authProbe = await ChatRealtimeService.I
                                .negotiateAuthProbe(
                                  hubUrl: '${ApiConstants.baseUrl}/chatHub',
                                  tokenProvider:
                                      () async =>
                                          await TokenService.getAccessToken() ??
                                          '',
                                );
                            setState(() {
                              diagnosticsResult =
                                  'AuthProbe: ' + (authProbe ?? 'failed');
                            });
                          },
                          child: const Text(
                            'AuthProbe',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final tok = _auth.userData?.token ?? '';
                            if (tok.isNotEmpty) {
                              final summary = ChatRealtimeService.I
                                  .summarizeToken(tok);
                              setState(() {
                                _tokenSummary = summary;
                                diagnosticsResult =
                                    (diagnosticsResult ?? '') +
                                    '\nToken: ' +
                                    summary;
                              });
                            }
                          },
                          child: const Text(
                            'Token',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final cid = ChatRealtimeService.I.connectionId;
                            if (cid != null) {
                              Clipboard.setData(ClipboardData(text: cid));
                              setState(() {
                                diagnosticsResult =
                                    (diagnosticsResult ?? '') +
                                    '\nConnId: ' +
                                    cid;
                              });
                              Get.snackbar(
                                'ConnId',
                                'Copied $cid',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                            } else {
                              setState(() {
                                diagnosticsResult =
                                    (diagnosticsResult ?? '') +
                                    '\nConnId: (null)';
                              });
                            }
                          },
                          child: const Text(
                            'ConnId',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => setState(
                                () => _showAdvanced = !_showAdvanced,
                              ),
                          child: Text(
                            _showAdvanced ? 'Hide +' : 'Show +',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 8),
                    Expanded(
                      child: ListView(
                        reverse: true,
                        children:
                            ChatRealtimeService.I.logs
                                .take(400)
                                .map(
                                  (l) => Text(
                                    l,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (diagnosticsResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                [
                  diagnosticsResult,
                  if (_tokenSummary != null) 'Claims: $_tokenSummary',
                ].whereType<String>().join('\n'),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
            ),
          const Divider(height: 0),
          Expanded(
            child:
                customers.isEmpty
                    ? const Center(child: Text('No customers yet'))
                    : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) {
                        final c = customers[i];
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(c['name']),
                          subtitle: Text(c['contact']),
                          onTap: () {
                            // Open specific thread with this buyer
                            Get.to(
                              () => LiveChatScreen(
                                productId: widget.productId,
                                productName: widget.productName,
                                farmerName: c['name'],
                                emailOrPhone: c['contact'],
                                receiverUserId: c['id'],
                              ),
                            )?.then((_) => _load());
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
