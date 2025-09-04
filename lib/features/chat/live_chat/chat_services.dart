// lib/features/chat/live_chat/chat_services.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:krishi_link/core/utils/api_constants.dart';
import 'package:krishi_link/services/token_service.dart';

class ChatRealtimeService {
  ChatRealtimeService._();
  static final ChatRealtimeService I = ChatRealtimeService._();

  HubConnection? _conn;
  bool _isConnecting = false;
  Object? _lastError;
  String? _lastErrorStack; // full stack of last failure (first cause)
  final List<String> _logs = <String>[]; // rolling log
  String? _lastUsedUrl;
  int _attemptCounter = 0; // total start attempts across connections
  int? _lastStartDurationMs; // duration of last successful start
  int? get lastStartDurationMs => _lastStartDurationMs;
  Future<String> Function()? _tokenProvider; // stored for later quick reconnect / send

  String? get lastUsedUrl => _lastUsedUrl;

  List<String> get logs => List.unmodifiable(_logs);
  void _log(String msg) {
    final line = '[${DateTime.now().toIso8601String().substring(11,19)}] $msg';
    debugPrint(line);
    _logs.add(line);
    if (_logs.length > 200) _logs.removeAt(0);
  }

  // Message stream from hub ReceiveMessage
  final _msgCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _msgCtrl.stream;

  // Connection state & errors for UI diagnostics / reconnection indicators
  final _stateCtrl = StreamController<HubConnectionState>.broadcast();
  Stream<HubConnectionState> get states => _stateCtrl.stream;

  final _errorCtrl = StreamController<Object>.broadcast();
  Stream<Object> get errors => _errorCtrl.stream;

  HubConnectionState get connectionState => _conn?.state ?? HubConnectionState.Disconnected;
  bool get isConnected => _conn?.state == HubConnectionState.Connected;
  Object? get lastError => _lastError;
  String? get lastErrorStack => _lastErrorStack;

  Future<bool> connect({
    required Future<String> Function() tokenProvider,
    String? hubUrl, // defaults to ${ApiConstants.baseUrl}/chatHub
    int serverTimeoutMs = 60000,
    int keepAliveIntervalMs = 15000,
    bool verbose = true,
    bool logFinalEnvOnFail = true,
    bool preflightDiagnostics = true,
  }) async {
    debugPrint('🚀 ChatRealtimeService.connect() called with enhanced diagnostics');
    if (isConnected) return true;
    if (_isConnecting) return false;
    _isConnecting = true;
    _tokenProvider = tokenProvider; // cache for later reconnect / token fetch
    
    // Preflight diagnostics - run comprehensive probe before attempting connection
    if (preflightDiagnostics) {
      try {
        debugPrint('🔍 === PREFLIGHT DIAGNOSTICS START ===');
        final env = envSummary();
        debugPrint('🔍 PreflightEnv: $env');
        
        final probeResults = await fullProbe(hubUrl: hubUrl, tokenProvider: tokenProvider);
        for (int i = 0; i < probeResults.length; i++) {
          debugPrint('🔍 Probe[$i]: ${probeResults[i]}');
        }
        debugPrint('🔍 === PREFLIGHT DIAGNOSTICS END ===');
      } catch (e) {
        debugPrint('🔍 Preflight diagnostics failed: $e');
      }
    }
    
    // Hub URL candidates (case + trailing slash variations)
    final base = hubUrl ?? '${ApiConstants.baseUrl}/chatHub';
    final capital = base.endsWith('/chatHub') ? base.replaceFirst('/chatHub', '/ChatHub') : base.replaceFirst('/chatHub/', '/ChatHub/');
    final candidates = <String>{
      base,
      if (!base.endsWith('/')) '$base/',
      base.replaceFirst('chatHub', 'chathub'),
      if (!base.toLowerCase().endsWith('/')) base.replaceFirst('chatHub', 'chathub') + '/',
      capital,
      if (!capital.endsWith('/')) '$capital/',
    };
    if (verbose) _log('Hub candidates: ${candidates.join(', ')}');    try {
      bool loggedToken = false;
      for (final url in candidates) {
        final token = await tokenProvider();
        if (!loggedToken) {
          if (token.isEmpty) {
            _log('SignalR: empty token provided');
          } else {
            final tokSummary = _summarizeToken(token);
            _log('Token summary: $tokSummary');
          }
          loggedToken = true;
        }
        // 1. Standard negotiate path with enhanced options
        if (verbose) _log('Attempt negotiate url=$url');
        debugPrint('🔗 Starting negotiate attempt for: $url');
        try {
          if (_conn != null) { try { await _conn!.stop(); } catch (_) {} }
          final opt = HttpConnectionOptions(
            accessTokenFactory: () async => token,
            // Prefer non-WS transport first due to proxy/CDN restrictions
            transport: HttpTransportType.LongPolling,
            // Set reasonable timeout
            requestTimeout: 30000, // 30s instead of default 100s
          );
          _conn = HubConnectionBuilder()
              .withUrl(url, options: opt)
              .withAutomaticReconnect()
              .build();
          _conn!.serverTimeoutInMilliseconds = serverTimeoutMs; // honor caller
          _conn!.keepAliveIntervalInMilliseconds = keepAliveIntervalMs;
          _setupCoreHandlers();
          debugPrint('🔗 Starting hub connection with timeout=${_conn!.serverTimeoutInMilliseconds}ms...');
          await _startWithRetry();
          if (isConnected) {
            _lastUsedUrl = url;
            _log('✅ Connected (negotiate) $url');
            debugPrint('🎉 Successfully connected via negotiate: $url');
            return true;
          }
        } catch (e, st) {
          _lastError = e;
          _lastErrorStack ??= st.toString();
          _log('❌ Negotiate failed $url -> $e\n${_shortStack(st)}');
          debugPrint('💥 Negotiate failed for $url: $e');
        }

        // 2. Direct websocket fallback (fresh token again in case refresh happened)
        if (verbose) _log('Attempt direct websocket url=$url');
        debugPrint('🔗 Trying direct WebSocket for: $url');
        try {
          if (_conn != null) { try { await _conn!.stop(); } catch (_) {} }
          final token2 = await tokenProvider();
          debugPrint('🔑 Got fresh token for WebSocket (length=${token2.length})');
          final optWs = HttpConnectionOptions(
            accessTokenFactory: () async => token2,
            skipNegotiation: true,
            transport: HttpTransportType.WebSockets,
            requestTimeout: 30000, // 30s timeout for WebSocket too
          );
          _conn = HubConnectionBuilder()
              .withUrl(url, options: optWs)
              .withAutomaticReconnect()
              .build();
          _conn!.serverTimeoutInMilliseconds = serverTimeoutMs; // honor caller
          _conn!.keepAliveIntervalInMilliseconds = keepAliveIntervalMs;
          _setupCoreHandlers();
          debugPrint('🔗 Starting direct WebSocket connection with timeout=${_conn!.serverTimeoutInMilliseconds}ms...');
          await _startWithRetry();
          if (isConnected) {
            _lastUsedUrl = url;
            _log('✅ Connected (ws fallback) $url');
            debugPrint('🎉 Successfully connected via direct WebSocket: $url');
            return true;
          }
        } catch (e, st) {
          _lastError = e;
          _lastErrorStack ??= st.toString();
          _log('❌ WebSocket direct failed $url -> $e\n${_shortStack(st)}');
          debugPrint('💥 Direct WebSocket failed for $url: $e');
        }
      }
      debugPrint('🔴 All connection attempts failed for all candidate URLs');
      return false;
    } finally {
      _isConnecting = false;
      if (!isConnected && logFinalEnvOnFail) {
        try {
          debugPrint('📊 === FINAL DIAGNOSTICS (Connection Failed) ===');
          final env = envSummary();
          debugPrint('📊 FinalEnv: $env');
          _log('FinalEnv: ' + env.toString());
          if (_lastErrorStack != null) {
            final firstLines = _lastErrorStack!.split('\n').take(20).join('\n');
            debugPrint('📊 LastErrorStack:\n$firstLines');
            _log('LastErrorStack:\n$firstLines');
          }
          debugPrint('📊 === END FINAL DIAGNOSTICS ===');
        } catch (e) {
          debugPrint('📊 Failed to generate final diagnostics: $e');
        }
      }
    }
  }

  /// Comprehensive token debugging to identify authentication issues
  Future<Map<String, dynamic>> tokenDebugCheck() async {
    final results = <String, dynamic>{};
    
    try {
      // Method 1: TokenService static method
      final token1 = await TokenService.getAccessToken();
      results['TokenService.getAccessToken'] = token1?.isNotEmpty == true ? 'Has token (${token1!.length} chars)' : 'NULL/Empty';
      
      // Method 2: Via stored tokenProvider
      if (_tokenProvider != null) {
        final token2 = await _tokenProvider!();
        results['_tokenProvider'] = token2.isNotEmpty ? 'Has token (${token2.length} chars)' : 'Empty';
        results['tokensMatch'] = token1 == token2 ? 'YES' : 'NO - MISMATCH!';
      } else {
        results['_tokenProvider'] = 'NULL - not set';
      }
      
      // Method 3: Check token expiration
      if (token1?.isNotEmpty == true) {
        final isExpired = await TokenService.isTokenExpired();
        results['tokenExpired'] = isExpired ? 'YES - EXPIRED!' : 'Valid';
        
        // Decode token details
        final summary = _summarizeToken(token1!);
        results['tokenSummary'] = summary;
        
        // Check auth headers
        final headers = await TokenService.getAuthHeaders();
        final authHeader = headers['Authorization'] ?? 'MISSING';
        results['authHeader'] = authHeader.length > 50 ? '${authHeader.substring(0, 50)}...' : authHeader;
      }
      
    } catch (e) {
      results['tokenDebugError'] = 'Failed: $e';
    }
    
    return results;
  }

  /// Quick server health check before attempting SignalR connection
  Future<Map<String, dynamic>> serverHealthCheck() async {
    final results = <String, dynamic>{};
    
    try {
      // Get token using the same method as SignalR connection
      final token = await _tokenProvider?.call() ?? '';
      if (token.isEmpty) {
        results['tokenAvailable'] = 'NO TOKEN - Authentication will fail';
        return results;
      }
      
      results['tokenAvailable'] = 'YES (${token.length} chars)';
      
      // Test basic connectivity to base URL
      final client = HttpClient();
      client.connectionTimeout = Duration(seconds: 10);
      
      // Test 1: Basic HTTP connectivity to base URL
      try {
        final uri = Uri.parse('${ApiConstants.baseUrl}/');
        final req = await client.getUrl(uri);
        final resp = await req.close();
        results['baseUrl'] = 'HTTP ${resp.statusCode}';
        await resp.drain();
      } catch (e) {
        results['baseUrl'] = 'Failed: $e';
      }
      
      // Test 2: Chat API endpoint with proper auth header (like React code)
      try {
        final uri = Uri.parse('${ApiConstants.baseUrl}/api/Chat/getMyCustomersForChat');
        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        req.headers.set(HttpHeaders.acceptHeader, '*/*');
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        final resp = await req.close();
        final body = await resp.transform(const Utf8Decoder()).join();
        results['chatAPI'] = 'HTTP ${resp.statusCode}';
        if (resp.statusCode != 200) {
          final snippet = body.length > 100 ? body.substring(0, 100) + '...' : body;
          results['chatAPIError'] = snippet;
        }
        await resp.drain();
      } catch (e) {
        results['chatAPI'] = 'Failed: $e';
      }
      
      // Test 3: Hub base URL
      try {
        final uri = Uri.parse('${ApiConstants.baseUrl}/ChatHub');
        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        final resp = await req.close();
        results['chatHub'] = 'HTTP ${resp.statusCode}';
        await resp.drain();
      } catch (e) {
        results['chatHub'] = 'Failed: $e';
      }
      
      client.close();
    } catch (e) {
      results['healthCheck'] = 'Failed: $e';
    }
    
    return results;
  }
  /// Returns (statusCode, bodyLength) or null on network failure.
  Future<String?> negotiateProbe(String? hubUrl) async {
    final baseHub = hubUrl ?? '${ApiConstants.baseUrl}/chatHub';
    final negotiateUrl = baseHub.endsWith('/') ? '${baseHub}negotiate?negotiateVersion=1' : '$baseHub/negotiate?negotiateVersion=1';
    try {
      _log('Probing negotiate: $negotiateUrl');
      final uri = Uri.parse(negotiateUrl);
      final client = HttpClient();
      final req = await client.getUrl(uri);
  // Add basic headers for potential 401 insight (no auth token here to intentionally test public reachability)
  req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final resp = await req.close();
      final bytes = await resp.fold<int>(0, (p, e) => p + e.length);
      final info = 'negotiate status=${resp.statusCode} bytes=$bytes';
      _log(info);
      return info;
    } catch (e) {
      _log('Negotiate probe error: $e');
      return null;
    }
  }

  /// Authenticated negotiate probe (POST like real SignalR) including Authorization header.
  Future<String?> negotiateAuthProbe({String? hubUrl, required Future<String> Function() tokenProvider}) async {
    final baseHub = hubUrl ?? '${ApiConstants.baseUrl}/chatHub';
    final negotiateUrl = baseHub.endsWith('/') ? '${baseHub}negotiate?negotiateVersion=1' : '$baseHub/negotiate?negotiateVersion=1';
    try {
      final token = await tokenProvider();
      _log('Probing negotiate AUTH: $negotiateUrl');
      final uri = Uri.parse(negotiateUrl);
      final client = HttpClient();
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token.isNotEmpty) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      // Empty JSON body (SignalR negotiates without required payload but POST allowed)
      req.add(const Utf8Encoder().convert('{}'));
      final resp = await req.close();
      final body = await resp.transform(const Utf8Decoder()).join();
      final snippet = body.length > 120 ? body.substring(0, 120) + '...' : body;
      final info = 'authNegotiate status=${resp.statusCode} len=${body.length} bodySnippet=$snippet';
      _log(info);
      return info;
    } catch (e) {
      _log('Negotiate auth probe error: $e');
      return null;
    }
  }

  void _setupCoreHandlers() {
    if (_conn == null) return;
    _conn!.on('ReceiveMessage', (List<Object?>? args) {
      try {
        if (args == null || args.isEmpty) return;
        // Supported signatures (server variability observed in React impl):
        // 1) (senderId, senderName, message)
        // 2) (senderId, message)
        // 3) (senderName, message)
        String? senderId;
        String senderName = 'Unknown';
        String message = '';
        if (args.length >= 3) {
          senderId = args[0] as String?;
          senderName = (args[1] as String?) ?? senderId ?? 'Unknown';
          message = (args[2] as String?) ?? '';
        } else if (args.length == 2) {
          // Try treat first as senderId, second as message
            senderId = args[0] as String?;
            message = (args[1] as String?) ?? '';
            // If message seems empty and second arg looks like name, fallback
            if (message.isEmpty && (args[1] is String)) {
              senderName = (args[0] as String?) ?? 'Unknown';
              message = (args[1] as String?) ?? '';
            } else {
              senderName = senderId ?? 'Unknown';
            }
        } else if (args.length == 1) {
          message = (args[0] as String?) ?? '';
        }
        if (message.isEmpty) return;
        _msgCtrl.add({
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('ReceiveMessage parse error: $e');
      }
    });
    _conn!.on('ReceiveSystemMessage', (List<Object?>? args) {
      try {
        if (args == null || args.isEmpty) return;
        final msg = (args.first as String?) ?? '';
        if (msg.isEmpty) return;
        _msgCtrl.add({
          'system': true,
          'message': msg,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('ReceiveSystemMessage parse error: $e');
      }
    });
    _conn!.onclose(({error}) async {
      debugPrint('SignalR closed: $error');
      _stateCtrl.add(HubConnectionState.Disconnected);
      if (error != null) _errorCtrl.add(error);
    });
    _conn!.onreconnecting(({error}) {
      debugPrint('SignalR reconnecting: $error');
      _stateCtrl.add(HubConnectionState.Reconnecting);
    });
    _conn!.onreconnected(({connectionId}) {
      debugPrint('SignalR reconnected: connectionId=$connectionId');
      _stateCtrl.add(HubConnectionState.Connected);
    });
  }

  Future<void> _startWithRetry({int maxAttempts = 5}) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        final startTs = DateTime.now();
        _attemptCounter++;
        debugPrint('🔗 SignalR start attempt $attempt (global $_attemptCounter)');
        debugPrint('🚀 Hub connection state before start: ${_conn?.state}');
        debugPrint('🔧 Connection details: url=${_conn?.baseUrl}, serverTimeout=${_conn?.serverTimeoutInMilliseconds}ms, keepAlive=${_conn?.keepAliveIntervalInMilliseconds}ms');
        
        // Add progress tracking with timeout
        bool startCompleted = false;
        late Timer progressTimer;
        int progressSeconds = 0;
        
        progressTimer = Timer.periodic(Duration(seconds: 5), (timer) {
          if (!startCompleted) {
            progressSeconds += 5;
            debugPrint('⏰ SignalR start progress: ${progressSeconds}s elapsed, state=${_conn?.state}');
            if (progressSeconds >= 30) {
              debugPrint('⚠️  SignalR start taking longer than 30s - potential connection issue');
            }
          }
        });
        
        try {
          debugPrint('🔄 Calling _conn.start()...');
          
          // Simple timeout approach - let the built-in timeout handle it
          // but add our own progress monitoring
          await _conn!.start();
          
          startCompleted = true;
          progressTimer.cancel();
          
          _stateCtrl.add(HubConnectionState.Connected);
          final dur = DateTime.now().difference(startTs).inMilliseconds;
          _lastStartDurationMs = dur;
          debugPrint('✅ SignalR connected in ${dur}ms (attempt $attempt)');
          debugPrint('🎯 Connection successful! ConnectionId: ${_conn?.connectionId}');
          debugPrint('🔗 Final state: ${_conn?.state}');
          return;
        } finally {
          startCompleted = true;
          progressTimer.cancel();
        }
      } catch (e, st) {
        _errorCtrl.add(e);
        final delay = Duration(milliseconds: 500 * attempt * attempt);
        final dur = DateTime.now().difference(DateTime.now().subtract(Duration(milliseconds: 1))).inMilliseconds;
        debugPrint('💥 SignalR start failed (attempt $attempt) after ${dur}ms: $e');
        debugPrint('⚠️  Error type: ${e.runtimeType}, Details: $e');
        debugPrint('🔍 Connection state at failure: ${_conn?.state}');
        _log('Start error attempt=$attempt type=${e.runtimeType} after=${dur}ms\n${_shortStack(st)}');
        
        if (attempt >= maxAttempts) {
          debugPrint('❌ All $maxAttempts attempts failed, giving up');
          rethrow;
        }
        debugPrint('⏳ Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
  }

  Future<void> ensureConnected(Future<String> Function() tokenProvider) async {
    if (!isConnected) {
      await connect(tokenProvider: tokenProvider);
    }
  }

  // Hub method: SendMessage(receiverUserId, message)
  Future<void> sendToUser(String receiverUserId, String text) async {
    if (text.trim().isEmpty) return;
    if (!isConnected) {
      debugPrint('Not connected, attempting quick reconnect before send');
      try {
        // If we have a stored token provider, try a fresh full connect (single attempt per candidate)
        if (_tokenProvider != null) {
          final ok = await connect(tokenProvider: _tokenProvider!, verbose: false);
          if (!ok) {
            debugPrint('Quick reconnect connect() path failed, abort send');
            return;
          }
        } else {
          await _startWithRetry(maxAttempts: 1);
        }
      } catch (e) {
        _errorCtrl.add(e);
        debugPrint('Reconnect before send failed: $e');
        return;
      }
    }
    try {
      await _conn?.invoke('SendMessage', args: <Object>[receiverUserId, text]);
    } catch (e) {
      _errorCtrl.add(e);
      debugPrint('SendMessage error: $e');
      rethrow;
    }
  }

  /// Expose current hub connection id for diagnostics/UI (null if not connected)
  String? get connectionId => _conn?.connectionId;

  /// Graceful disconnect that stops the underlying hub.
  Future<void> disconnect() async {
    try { await _conn?.stop(); } catch (_) {}
  }

  // No-op shims for legacy room-based calls in older controllers
  Future<void> joinRoom(String roomId) async {
    /* backend has no rooms */
  }
  Future<void> leaveRoom(String roomId) async {
    /* backend has no rooms */
  }

  Future<void> dispose() async {
    try {
      await _conn?.stop();
    } catch (_) {}
    await _msgCtrl.close();
    await _stateCtrl.close();
    await _errorCtrl.close();
  }

  // ====== Diagnostics Helpers ======
  Map<String, dynamic> snapshot() => {
    'connected': isConnected,
    'state': connectionState.toString(),
    'lastError': lastError?.toString(),
    'lastUsedUrl': _lastUsedUrl,
    'attemptCounter': _attemptCounter,
    'lastStartDurationMs': _lastStartDurationMs,
    'logCount': _logs.length,
    'timestamp': DateTime.now().toIso8601String(),
  };

  String exportLogs() => _logs.join('\n');

  void clearLogs() {
    _logs.clear();
    _log('Logs cleared');
  }

  // Public wrapper so UI can show token claims summary.
  String summarizeToken(String token) => _summarizeToken(token);

  // ============ Advanced Diagnostics ============

  /// Returns a map with runtime & service diagnostics useful for UI.
  Map<String, dynamic> envSummary() {
    return {
      'connected': isConnected,
      'connectionId': _conn?.connectionId,
      'state': connectionState.toString(),
      'lastUsedUrl': _lastUsedUrl,
      'attemptCounter': _attemptCounter,
      'lastStartDurationMs': _lastStartDurationMs,
      'lastError': _lastError?.toString(),
      'lastErrorStackShort': _lastErrorStack == null ? null : _lastErrorStack!.split('\n').take(6).join('\n'),
      'logCount': _logs.length,
      'now': DateTime.now().toIso8601String(),
      'platform': _platformSummary(),
    };
  }

  String _platformSummary() {
    try {
      return '${Platform.operatingSystem} ${Platform.version.split(' ').first}';
    } catch (_) {
      return 'unknown-platform';
    }
  }

  /// DNS lookup (skipped on web where dart:io lookup not supported).
  Future<String> dnsLookup(String hubUrl) async {
    try {
      final uri = Uri.parse(hubUrl);
      if (uri.host.isEmpty) return 'invalid host';
      final list = await InternetAddress.lookup(uri.host);
      final ips = list.map((e) => e.address).join(', ');
      final msg = 'DNS ${uri.host} -> $ips';
      _log(msg);
      return msg;
    } catch (e) {
      final msg = 'DNS error: $e';
      _log(msg);
      return msg;
    }
  }

  /// Simple GET/HEAD probe to arbitrary path (optionally with bearer token) to see raw status.
  Future<String> probeHttp({required String url, String? bearer, String method = 'GET'}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse(url);
      final req = await (method == 'HEAD' ? client.openUrl('HEAD', uri) : client.openUrl(method, uri));
      if (bearer != null && bearer.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      }
      req.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*');
      final resp = await req.close().timeout(const Duration(seconds: 20));
      final firstKb = <int>[];
      await for (final chunk in resp) {
        if (firstKb.length < 1024) {
            firstKb.addAll(chunk.take(1024 - firstKb.length));
        }
      }
      final bodySnippet = utf8.decode(firstKb, allowMalformed: true);
      final info = 'probe $method ${uri.path} status=${resp.statusCode} bytes=${firstKb.length} snippet="${bodySnippet.replaceAll('\n', ' ').substring(0, bodySnippet.length.clamp(0, 160))}"';
      _log(info);
      return info;
    } catch (e) {
      final info = 'probe error $method $url -> $e';
      _log(info);
      return info;
    }
  }

  /// Performs a comprehensive set of probes for a hub base URL.
  Future<List<String>> fullProbe({String? hubUrl, required Future<String> Function() tokenProvider}) async {
    final baseHub = hubUrl ?? '${ApiConstants.baseUrl}/chatHub';
    final out = <String>[];
    _log('--- FULL PROBE START base=$baseHub ---');
    out.add('base=$baseHub');
    out.add(await dnsLookup(baseHub));
    final token = await tokenProvider();
    out.add('tokenLen=${token.length} tokenSummary=${token.isEmpty ? 'none' : _summarizeToken(token)}');
    // Unauth negotiate GET
  final negPlain = await negotiateProbe(baseHub);
  out.add(negPlain ?? 'negotiateProbe null');
  // Auth negotiate POST
  final negAuth = await negotiateAuthProbe(hubUrl: baseHub, tokenProvider: () async => token);
  out.add(negAuth ?? 'authNegotiate null');
    // Root GET (unauth & auth)
    final root = baseHub.endsWith('/chatHub') || baseHub.endsWith('/ChatHub') ? baseHub : baseHub; // already full
    out.add(await probeHttp(url: root, method: 'GET'));
    out.add(await probeHttp(url: root, method: 'GET', bearer: token));
    // /negotiate direct GET/POST manual
    final negUrl = root.endsWith('/') ? '${root}negotiate?negotiateVersion=1' : '$root/negotiate?negotiateVersion=1';
    out.add(await probeHttp(url: negUrl, method: 'GET'));
    out.add(await probeHttp(url: negUrl, method: 'GET', bearer: token));
    out.add(await probeHttp(url: negUrl, method: 'POST', bearer: token));
    _log('--- FULL PROBE END ---');
    return out;
  }

  String _summarizeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'invalid-jwt';
      final payload = _decodeBase64(parts[1]);
      final map = _tryDecodeJson(payload);
      if (map == null) return 'unparsable-jwt';
      final sub = map['sub'] ?? map['nameid'] ?? map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
      final role = map['role'] ?? map['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      final exp = map['exp'];
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final ttl = exp is int ? (exp - nowSec) : null;
      return 'sub=$sub role=$role ttlSec=${ttl ?? '?'}';
    } catch (_) {
      return 'token-parse-error';
    }
  }

  /// Alternative connection method that specifically tries Server-Sent Events 
  /// (not WebSocket) as a fallback when WebSocket fails/times out
  Future<bool> connectWithServerSentEvents({
    required Future<String> Function() tokenProvider,
    String? hubUrl,
    int serverTimeoutMs = 30000, // Shorter default for testing
    int keepAliveIntervalMs = 15000,
  }) async {
    debugPrint('📺 Attempting Server-Sent Events connection as WebSocket alternative');
    if (isConnected) return true;
    if (_isConnecting) return false;
    _isConnecting = true;
    _tokenProvider = tokenProvider;
    
    try {
      final url = hubUrl ?? '${ApiConstants.baseUrl}/chatHub';
      final token = await tokenProvider();
      debugPrint('📺 SSE URL: $url, token length: ${token.length}');
      
      if (_conn != null) { 
        try { await _conn!.stop(); } catch (_) {} 
      }
      
      final opt = HttpConnectionOptions(
        accessTokenFactory: () async => token,
        transport: HttpTransportType.ServerSentEvents, // Force SSE
        requestTimeout: 30000,
      );
      
      _conn = HubConnectionBuilder()
          .withUrl(url, options: opt)
          .withAutomaticReconnect()
          .build();
      _conn!.serverTimeoutInMilliseconds = serverTimeoutMs;
      _conn!.keepAliveIntervalInMilliseconds = keepAliveIntervalMs;
      _setupCoreHandlers();
      
      debugPrint('📺 Starting Server-Sent Events connection...');
      await _startWithRetry(maxAttempts: 2); // Only 2 attempts for testing
      
      if (isConnected) {
        _lastUsedUrl = url;
        debugPrint('📺 SUCCESS: Connected via Server-Sent Events!');
        return true;
      }
      
      return false;
    } catch (e, st) {
      _lastError = e;
      _lastErrorStack = st.toString();
      debugPrint('📺 Server-Sent Events connection failed: $e');
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  String _decodeBase64(String str) {
    String out = str.replaceAll('-', '+').replaceAll('_', '/');
    while (out.length % 4 != 0) { out += '='; }
    return String.fromCharCodes(base64Url.decode(out));
  }

  Map<String, dynamic>? _tryDecodeJson(String jsonStr) {
    try {
      final obj = jsonDecode(jsonStr);
      return obj is Map<String, dynamic> ? obj : null;
    } catch (_) {
      return null;
    }
  }

  String _shortStack(StackTrace st) {
    final lines = st.toString().split('\n');
    return lines.take(4).join('\n');
  }
}
