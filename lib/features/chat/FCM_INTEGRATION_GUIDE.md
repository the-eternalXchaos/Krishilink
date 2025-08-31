# Firebase Cloud Messaging (FCM) Integration Guide

## Overview

This guide explains the FCM integration for the KrishiLink chat feature, which handles push notifications for offline messages and real-time chat updates.

## Files Created

### 1. `lib/features/chat/services/fcm_service.dart`
- **Purpose**: Main FCM service that handles token management, notification display, and message processing
- **Key Features**:
  - FCM token generation and server registration
  - Topic subscription for targeted notifications
  - Local notification display
  - Message parsing and processing
  - Notification tap handling

### 2. `lib/features/chat/services/background_message_handler.dart`
- **Purpose**: Handles FCM messages when the app is in background or terminated
- **Key Features**:
  - Background message processing
  - Local cache updates
  - Chat room metadata updates

### 3. Updated `lib/features/chat/controllers/chat_controller.dart`
- **Added**: FCM integration methods
- **New Methods**:
  - `initializeFCM()`: Initialize FCM for current user
  - `subscribeToChatRoomNotifications()`: Subscribe to chat room topics
  - `unsubscribeFromChatRoomNotifications()`: Unsubscribe from topics
  - `clearChatNotifications()`: Clear notifications for a chat room
  - `updateFCMToken()`: Update FCM token
  - `handleNotificationTap()`: Handle notification navigation

### 4. Updated `lib/features/chat/bindings/chat_binding.dart`
- **Added**: FCM service registration in dependency injection

## Setup Requirements

### 1. Firebase Configuration

#### Android Setup
1. Add `google-services.json` to `android/app/`
2. Update `android/app/build.gradle`:
   ```gradle
   dependencies {
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
       implementation 'com.google.firebase:firebase-messaging'
   }
   ```
3. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```

#### iOS Setup
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Update `ios/Runner/AppDelegate.swift`:
   ```swift
   import UIKit
   import Flutter
   import Firebase
   import FirebaseMessaging

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       FirebaseApp.configure()
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

### 2. Main App Initialization

Update `lib/main.dart` to initialize Firebase and register the background handler:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/chat/services/background_message_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Hive
  await Hive.initFlutter();
  
  runApp(MyApp());
}
```

### 3. UserModel Requirements

The FCM service expects the `UserModel` to have an `id` property. Update your `UserModel` class:

```dart
class UserModel {
  final String id;
  final String name;
  // ... other properties
  
  UserModel({
    required this.id,
    required this.name,
    // ... other parameters
  });
  
  // ... fromJson, toJson methods
}
```

## API Integration

### 1. Server-Side FCM Token Registration

Implement an API endpoint to register FCM tokens:

```dart
// In ChatApiService
Future<void> registerFCMToken(String token) async {
  try {
    final options = await _getAuthOptions();
    await _dio.post(
      '/api/chat/register-fcm-token',
      data: {'fcmToken': token},
      options: options,
    );
  } catch (e) {
    _logger.e('Failed to register FCM token: $e');
  }
}
```

### 2. Backend FCM Implementation

Your .NET backend should:

1. **Store FCM tokens** for each user
2. **Send notifications** when messages are received offline
3. **Use topics** for targeted notifications

Example C# implementation:
```csharp
public class ChatHub : Hub
{
    public async Task SendMessage(string chatRoomId, string content, string messageType)
    {
        // Save message to database
        var message = await SaveMessageToDatabase(chatRoomId, content, messageType);
        
        // Send to online users via SignalR
        await Clients.Group(chatRoomId).SendAsync("ReceiveMessage", message);
        
        // Send FCM notification to offline users
        await SendFCMNotificationToOfflineUsers(chatRoomId, message);
    }
    
    private async Task SendFCMNotificationToOfflineUsers(string chatRoomId, Message message)
    {
        var offlineUsers = await GetOfflineUsersInChatRoom(chatRoomId);
        
        foreach (var user in offlineUsers)
        {
            var notification = new
            {
                to = $"/topics/user_{user.Id}",
                data = new
                {
                    type = "chat_message",
                    chatRoomId = chatRoomId,
                    messageId = message.Id,
                    senderId = message.SenderId,
                    senderName = message.SenderName,
                    content = message.Content,
                    messageType = message.Type,
                    timestamp = message.Timestamp.ToString("O")
                },
                notification = new
                {
                    title = message.SenderName,
                    body = message.Content,
                    sound = "default"
                }
            };
            
            await SendFCMNotification(notification);
        }
    }
}
```

## Usage Examples

### 1. Initialize FCM on User Login

```dart
// In your login controller or service
Future<void> onLoginSuccess() async {
  // ... existing login logic
  
  // Initialize FCM
  final chatController = Get.find<ChatController>();
  await chatController.initializeFCM();
  await chatController.updateFCMToken();
}
```

### 2. Subscribe to Chat Room Notifications

```dart
// When entering a chat room
Future<void> enterChatRoom(ChatRoom chatRoom) async {
  final chatController = Get.find<ChatController>();
  await chatController.subscribeToChatRoomNotifications(chatRoom.id);
  
  // Load messages and navigate
  await chatController.loadMessages(chatRoom.id);
  Get.toNamed('/chat/thread', arguments: chatRoom);
}
```

### 3. Unsubscribe When Leaving Chat Room

```dart
// When leaving a chat room
Future<void> leaveChatRoom(String chatRoomId) async {
  final chatController = Get.find<ChatController>();
  await chatController.unsubscribeFromChatRoomNotifications(chatRoomId);
  chatController.clearCurrentChat();
}
```

## Notification Data Format

FCM notifications should include the following data structure:

```json
{
  "type": "chat_message",
  "chatRoomId": "room_123",
  "messageId": "msg_456",
  "senderId": "user_789",
  "senderName": "John Doe",
  "content": "Hello! Is this product still available?",
  "messageType": "text",
  "timestamp": "2024-01-15T10:30:00Z",
  "mediaUrl": "https://example.com/image.jpg",
  "mediaThumbnail": "https://example.com/thumb.jpg",
  "mediaFileName": "product_image.jpg",
  "mediaFileSize": "1024000",
  "mediaDuration": "30",
  "metadata": "{\"productId\":\"prod_123\",\"productName\":\"Organic Tomatoes\"}"
}
```

## Troubleshooting

### Common Issues

1. **FCM Token Not Generated**
   - Ensure Firebase is properly initialized
   - Check internet connectivity
   - Verify Google Services configuration

2. **Notifications Not Received**
   - Check FCM token registration with server
   - Verify topic subscription
   - Ensure notification permissions are granted

3. **Background Messages Not Processed**
   - Verify background handler registration
   - Check Hive initialization
   - Ensure proper error handling

### Debug Commands

```dart
// Check FCM token
final fcmService = Get.find<FcmService>();
print('FCM Token: ${fcmService.fcmToken}');

// Check connection status
final signalRService = Get.find<SignalRService>();
print('SignalR Connected: ${signalRService.isConnected}');

// Check cached messages
final cacheService = Get.find<ChatCacheService>();
final messages = cacheService.getMessages('chatRoomId');
print('Cached Messages: ${messages.length}');
```

## Security Considerations

1. **Token Validation**: Always validate FCM tokens on the server
2. **User Authentication**: Ensure users can only receive notifications for their chats
3. **Rate Limiting**: Implement rate limiting for FCM notifications
4. **Data Encryption**: Consider encrypting sensitive message content

## Performance Optimization

1. **Batch Notifications**: Group multiple notifications when possible
2. **Topic Management**: Use topics for efficient message routing
3. **Cache Management**: Implement proper cache cleanup strategies
4. **Background Processing**: Use background tasks for heavy operations

## Testing

### Manual Testing Checklist

- [ ] FCM token generation on app start
- [ ] Token registration with server
- [ ] Topic subscription/unsubscription
- [ ] Foreground notification display
- [ ] Background message processing
- [ ] Notification tap navigation
- [ ] Offline message sync
- [ ] Chat room notification management

### Automated Testing

Create unit tests for:
- FCM service initialization
- Message parsing
- Notification handling
- Topic management
- Error scenarios

## Future Enhancements

1. **Rich Notifications**: Add image previews and action buttons
2. **Notification Groups**: Group notifications by chat room
3. **Custom Sounds**: Implement custom notification sounds
4. **Silent Notifications**: Use silent notifications for data sync
5. **Notification Analytics**: Track notification engagement

## Support

For issues related to:
- **Firebase Setup**: Check Firebase documentation
- **FCM Configuration**: Review Firebase Console settings
- **Platform-Specific Issues**: Check platform-specific setup guides
- **Integration Problems**: Review this guide and error logs 