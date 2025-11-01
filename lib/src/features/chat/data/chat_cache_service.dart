import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches light-weight chat metadata like customer display names by ID.
class ChatCacheService {
  static const _prefsKey = 'chat_name_cache_v1';
  static const _listKey = 'chat_list_cache_v1';
  static final ChatCacheService I = ChatCacheService._internal();

  ChatCacheService._internal();

  Map<String, String> _names = <String, String>{};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _names = decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''))
            ..removeWhere((key, value) => value.isEmpty);
        }
      }
      _loaded = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ChatCache load failed: $e');
      }
      _loaded = true; // Avoid retry storms
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_names));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ ChatCache persist failed: $e');
      }
    }
  }

  /// Returns a cached display name for a given customer [id], if any.
  Future<String?> getName(String id) async {
    await _ensureLoaded();
    return _names[id];
  }

  /// Upserts the display [name] for a given customer [id].
  Future<void> upsertName(String id, String name) async {
    if (id.isEmpty || name.trim().isEmpty) return;
    await _ensureLoaded();
    final normalized = name.trim();
    final existing = _names[id];
    if (existing == null || existing != normalized) {
      _names[id] = normalized;
      await _persist();
    }
  }

  /// Bulk set names (does not remove existing unless overridden)
  Future<void> upsertMany(Map<String, String> entries) async {
    await _ensureLoaded();
    var changed = false;
    entries.forEach((id, name) {
      final n = name.trim();
      if (id.isEmpty || n.isEmpty) return;
      if (_names[id] != n) {
        _names[id] = n;
        changed = true;
      }
    });
    if (changed) await _persist();
  }

  /// Returns a nicer fallback if we don't know the name yet.
  String prettyFallback(String id, {String prefix = 'Buyer'}) {
    if (id.isEmpty) return prefix;
    if (id.length <= 8) return '$prefix-$id';
    final start = id.substring(0, 4);
    final end = id.substring(id.length - 4);
    return '$prefix-$start…$end';
  }

  /// Persist a lightweight cached customer list for quick startup.
  /// Each item should contain at least {'id': String, 'name': String, 'contact': String}
  Future<void> saveCustomerList(List<Map<String, dynamic>> customers) async {
    try {
      final normalized = customers
          .map(
            (e) => {
              'id': (e['id'] ?? '').toString(),
              'name': (e['name'] ?? '').toString(),
              'contact': (e['contact'] ?? '').toString(),
              'unread': int.tryParse((e['unread'] ?? 0).toString()) ?? 0,
            },
          )
          .where((e) => ((e['id'] ?? '') as String).isNotEmpty)
          .toList(growable: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_listKey, jsonEncode(normalized));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Chat list persist failed: $e');
      }
    }
  }

  /// Load cached customer list, if any.
  Future<List<Map<String, dynamic>>> loadCustomerList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_listKey);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .map((e) => {
                  'id': (e['id'] ?? '').toString(),
                  'name': (e['name'] ?? '').toString(),
                  'contact': (e['contact'] ?? '').toString(),
                  'unread': int.tryParse((e['unread'] ?? 0).toString()) ?? 0,
                })
            .toList(growable: false);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Chat list load failed: $e');
      }
      return <Map<String, dynamic>>[];
    }
  }
}
