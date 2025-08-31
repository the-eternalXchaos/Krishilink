import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/hive_adapters.dart';

class ChatCacheService extends GetxService {
  static const String _chatRoomsBox = 'chat_rooms';
  static const String _messagesBox = 'messages';
  static const String _pendingMessagesBox = 'pending_messages';
  static const String _userInfoBox = 'user_info';

  late Box<ChatRoom> _chatRoomsBoxInstance;
  late Box<Message> _messagesBoxInstance;
  late Box<Message> _pendingMessagesBoxInstance;
  late Box<Map> _userInfoBoxInstance;

  @override
  void onInit() {
    super.onInit();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    // TODO: Register adapters after Hive code generation is fixed
    // Hive.registerAdapter(MessageTypeAdapter());
    // Hive.registerAdapter(MessageStatusAdapter());
    // Hive.registerAdapter(ChatRoomAdapter());
    // Hive.registerAdapter(MessageAdapter());

    // Open boxes
    _chatRoomsBoxInstance = await Hive.openBox<ChatRoom>(_chatRoomsBox);
    _messagesBoxInstance = await Hive.openBox<Message>(_messagesBox);
    _pendingMessagesBoxInstance = await Hive.openBox<Message>(
      _pendingMessagesBox,
    );
    _userInfoBoxInstance = await Hive.openBox<Map>(_userInfoBox);
  }

  // Chat Rooms
  Future<void> saveChatRoom(ChatRoom chatRoom) async {
    await _chatRoomsBoxInstance.put(chatRoom.id, chatRoom);
  }

  Future<void> saveChatRooms(List<ChatRoom> chatRooms) async {
    final Map<String, ChatRoom> chatRoomsMap = {
      for (var room in chatRooms) room.id: room,
    };
    await _chatRoomsBoxInstance.putAll(chatRoomsMap);
  }

  List<ChatRoom> getAllChatRooms() {
    return _chatRoomsBoxInstance.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  ChatRoom? getChatRoom(String chatRoomId) {
    return _chatRoomsBoxInstance.get(chatRoomId);
  }

  Future<void> updateChatRoom(ChatRoom chatRoom) async {
    await _chatRoomsBoxInstance.put(chatRoom.id, chatRoom);
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    await _chatRoomsBoxInstance.delete(chatRoomId);
    // Also delete all messages for this chat room
    await deleteAllMessages(chatRoomId);
  }

  // Messages
  Future<void> saveMessage(Message message) async {
    await _messagesBoxInstance.put(
      '${message.chatRoomId}_${message.id}',
      message,
    );
  }

  Future<void> saveMessages(List<Message> messages) async {
    final Map<String, Message> messagesMap = {
      for (var message in messages)
        '${message.chatRoomId}_${message.id}': message,
    };
    await _messagesBoxInstance.putAll(messagesMap);
  }

  List<Message> getMessages(String chatRoomId, {int limit = 50}) {
    final messages =
        _messagesBoxInstance.values
            .where((message) => message.chatRoomId == chatRoomId)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (limit > 0 && messages.length > limit) {
      return messages.sublist(messages.length - limit);
    }
    return messages;
  }

  Message? getMessage(String chatRoomId, String messageId) {
    return _messagesBoxInstance.get('${chatRoomId}_$messageId');
  }

  Future<void> updateMessage(Message message) async {
    await _messagesBoxInstance.put(
      '${message.chatRoomId}_${message.id}',
      message,
    );
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _messagesBoxInstance.delete('${chatRoomId}_$messageId');
  }

  Future<void> deleteAllMessages(String chatRoomId) async {
    final keysToDelete =
        _messagesBoxInstance.keys
            .where((key) => key.toString().startsWith('${chatRoomId}_'))
            .toList();
    await _messagesBoxInstance.deleteAll(keysToDelete);
  }

  // Pending Messages (for offline sync)
  Future<void> savePendingMessage(Message message) async {
    await _pendingMessagesBoxInstance.put(
      '${message.chatRoomId}_${message.id}',
      message,
    );
  }

  List<Message> getPendingMessages() {
    return _pendingMessagesBoxInstance.values.toList();
  }

  Future<void> removePendingMessage(String chatRoomId, String messageId) async {
    await _pendingMessagesBoxInstance.delete('${chatRoomId}_$messageId');
  }

  Future<void> clearPendingMessages() async {
    await _pendingMessagesBoxInstance.clear();
  }

  // User Info Cache
  Future<void> saveUserInfo(
    String userId,
    Map<String, dynamic> userInfo,
  ) async {
    await _userInfoBoxInstance.put(userId, userInfo);
  }

  Map<String, dynamic>? getUserInfo(String userId) {
    return _userInfoBoxInstance.get(userId) as Map<String, dynamic>?;
  }

  // Utility methods
  int getUnreadCount(String chatRoomId) {
    return _messagesBoxInstance.values
        .where(
          (message) =>
              message.chatRoomId == chatRoomId &&
              !message.isFromMe &&
              message.status != MessageStatus.read,
        )
        .length;
  }

  DateTime? getLastMessageTime(String chatRoomId) {
    final messages =
        _messagesBoxInstance.values
            .where((message) => message.chatRoomId == chatRoomId)
            .toList();

    if (messages.isEmpty) return null;

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.first.timestamp;
  }

  String? getLastMessage(String chatRoomId) {
    final messages =
        _messagesBoxInstance.values
            .where((message) => message.chatRoomId == chatRoomId)
            .toList();

    if (messages.isEmpty) return null;

    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.first.content;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _chatRoomsBoxInstance.clear();
    await _messagesBoxInstance.clear();
    await _pendingMessagesBoxInstance.clear();
    await _userInfoBoxInstance.clear();
  }

  // Get storage size
  Future<int> getStorageSize() async {
    int size = 0;
    size += _chatRoomsBoxInstance.length;
    size += _messagesBoxInstance.length;
    size += _pendingMessagesBoxInstance.length;
    size += _userInfoBoxInstance.length;
    return size;
  }

  @override
  void onClose() {
    _chatRoomsBoxInstance.close();
    _messagesBoxInstance.close();
    _pendingMessagesBoxInstance.close();
    _userInfoBoxInstance.close();
    super.onClose();
  }
}
