# KrishiLink Chat Feature

A comprehensive real-time chat system for the KrishiLink Flutter app with SignalR backend integration, local caching, and modern UI design.

## 🚀 Features

### Core Features
- **Real-time messaging** using SignalR WebSocket connection
- **Local caching** with Hive for offline support
- **Push notifications** via Firebase Cloud Messaging
- **Media support** (images, documents, voice notes, videos)
- **Typing indicators** and read receipts
- **Message status** tracking (sending, sent, delivered, read, failed)
- **Reply functionality** for messages
- **Product integration** with predefined messages

### UI Features
- **WhatsApp/Messenger-style** interface
- **Chat list** with unread counts and last message preview
- **Chat thread** with message bubbles and timestamps
- **Predefined messages** for product inquiries
- **Attachment support** with camera, gallery, and document picker
- **Responsive design** for all screen sizes

## 📁 Project Structure

```
lib/features/chat/
├── bindings/
│   └── chat_binding.dart          # Dependency injection
├── controllers/
│   └── chat_controller.dart       # Main chat logic
├── models/
│   ├── chat_room.dart            # Chat room model with Hive
│   ├── message.dart              # Message model with Hive
│   └── hive_adapters.dart        # Hive type adapters
├── routes/
│   └── chat_routes.dart          # Navigation routes
├── screens/
│   ├── chat_list_screen.dart     # Chat rooms list
│   └── chat_thread_screen.dart   # Individual chat thread
├── services/
│   ├── chat_api_service.dart     # REST API communication
│   ├── chat_cache_service.dart   # Local storage with Hive
│   └── signalr_service.dart      # SignalR WebSocket
├── widgets/
│   ├── message_bubble.dart       # Individual message display
│   ├── typing_indicator.dart     # Typing animation
│   └── predefined_messages.dart  # Quick message buttons
└── README.md                     # This file
```

## 🏗️ Architecture

### Clean Architecture with GetX
- **Controllers**: Business logic and state management
- **Services**: API communication and local storage
- **Models**: Data structures with Hive annotations
- **Views**: UI components and screens
- **Bindings**: Dependency injection

### Data Flow
```
SignalR → ChatController → Update UI → Save to Hive → API sync
```

## 📱 UI Design

### Chat List Screen
- Avatar with online status indicator
- User name and last message preview
- Timestamp and unread count badge
- Pull-to-refresh functionality
- Search and options menu

### Chat Thread Screen
- Message bubbles with different colors for sent/received
- Timestamp and status indicators
- Reply preview with quoted message
- Attachment menu (camera, gallery, documents, location)
- Typing indicator animation
- Date dividers for message organization

### Predefined Messages Widget
- Quick message buttons for common inquiries
- Product information auto-attachment
- Custom chat option
- Integration with product details page

## 🔧 Setup Instructions

### 1. Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  signalr_netcore: ^1.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.0+1
  image_picker: ^1.0.4
  video_player: ^2.8.3
  audio_waveforms: ^1.0.4
  record: ^5.0.4
  permission_handler: ^12.0.0+1
  connectivity_plus: ^6.0.5
  workmanager: ^0.5.2

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.13
```

### 2. Generate Hive Models
Run the following command to generate Hive adapters:
```bash
flutter packages pub run build_runner build
```

### 3. Initialize Hive
Add to `main.dart`:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'features/chat/models/hive_adapters.dart';

void main() async {
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(MessageStatusAdapter());
  Hive.registerAdapter(ChatRoomAdapter());
  Hive.registerAdapter(MessageAdapter());
  
  runApp(MyApp());
}
```

### 4. Add Routes
Add to your main routes:
```dart
import 'features/chat/routes/chat_routes.dart';

GetMaterialApp(
  getPages: [
    ...ChatRoutes.routes,
    // other routes
  ],
)
```

### 5. Initialize Chat Binding
Add to your app initialization:
```dart
import 'features/chat/bindings/chat_binding.dart';

// In your app initialization
ChatBinding().dependencies();
```

## 🔌 API Integration

### Backend Requirements (.NET with SignalR)

#### SignalR Hub Methods
```csharp
public class ChatHub : Hub
{
    // Client methods
    public async Task SendMessage(string chatRoomId, string content, string type, string mediaUrl, string replyToMessageId, object metadata)
    public async Task SendTypingIndicator(string chatRoomId, bool isTyping)
    public async Task JoinChatRoom(string chatRoomId)
    public async Task LeaveChatRoom(string chatRoomId)
    public async Task MarkMessageAsRead(string messageId)
    
    // Server methods (called from client)
    public async Task ReceiveMessage(Message message)
    public async Task UserTyping(string userId, bool isTyping)
    public async Task UserOnline(string userId)
    public async Task UserOffline(string userId)
    public async Task MessageRead(string messageId)
}
```

#### REST API Endpoints
```
GET    /api/chat/rooms                    # Get chat rooms
POST   /api/chat/rooms                    # Create chat room
GET    /api/chat/rooms/{id}/messages      # Get messages
POST   /api/chat/rooms/{id}/messages      # Send message
PUT    /api/chat/rooms/{id}/read          # Mark as read
POST   /api/chat/rooms/{id}/typing        # Typing indicator
POST   /api/chat/upload-media             # Upload media
GET    /api/users/{id}                    # Get user info
```

## 📊 Database Schema

### ChatRoom Table
```sql
CREATE TABLE ChatRooms (
    Id NVARCHAR(450) PRIMARY KEY,
    Name NVARCHAR(255) NOT NULL,
    Avatar NVARCHAR(500),
    ParticipantId NVARCHAR(450) NOT NULL,
    ParticipantName NVARCHAR(255) NOT NULL,
    ParticipantRole NVARCHAR(50) NOT NULL,
    LastMessage NVARCHAR(MAX),
    LastMessageTime DATETIME2,
    UnreadCount INT DEFAULT 0,
    IsOnline BIT DEFAULT 0,
    ProductId NVARCHAR(450),
    ProductName NVARCHAR(255),
    CreatedAt DATETIME2 NOT NULL,
    UpdatedAt DATETIME2 NOT NULL
);
```

### Message Table
```sql
CREATE TABLE Messages (
    Id NVARCHAR(450) PRIMARY KEY,
    ChatRoomId NVARCHAR(450) NOT NULL,
    SenderId NVARCHAR(450) NOT NULL,
    SenderName NVARCHAR(255) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,
    Type NVARCHAR(50) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    Timestamp DATETIME2 NOT NULL,
    MediaUrl NVARCHAR(500),
    MediaThumbnail NVARCHAR(500),
    MediaDuration INT,
    MediaFileName NVARCHAR(255),
    MediaFileSize INT,
    Metadata NVARCHAR(MAX),
    IsFromMe BIT NOT NULL,
    ReplyToMessageId NVARCHAR(450),
    ReplyToMessageContent NVARCHAR(MAX),
    FOREIGN KEY (ChatRoomId) REFERENCES ChatRooms(Id)
);
```

## 🚀 Usage Examples

### Starting a Chat from Product Details
```dart
// Add to product details page
PredefinedMessages(
  farmerId: product.farmerId,
  farmerName: product.farmerName,
  productId: product.id,
  productName: product.name,
  productPrice: product.price,
)
```

### Navigating to Chat List
```dart
Get.toNamed('/chat/list');
```

### Sending a Message Programmatically
```dart
final chatController = Get.find<ChatController>();
await chatController.sendMessage(
  content: 'Hello!',
  type: MessageType.text,
);
```

### Creating a Chat Room
```dart
final chatRoom = await chatController.createChatRoom(
  participantId: 'user123',
  productId: 'product456',
  initialMessage: 'Hi, I\'m interested in your product!',
);
```

## 🔄 State Management

### Observable Variables
- `chatRooms`: List of chat rooms
- `messages`: Current chat messages
- `isLoading`: Loading states
- `isConnected`: SignalR connection status
- `isTyping`: Typing indicator
- `totalUnreadCount`: Total unread messages

### Key Methods
- `loadChatRooms()`: Load chat rooms from API/cache
- `loadMessages(chatRoomId)`: Load messages for a chat
- `sendMessage(content)`: Send a new message
- `createChatRoom(participantId)`: Create new chat room
- `markMessagesAsRead(chatRoomId)`: Mark messages as read

## 🔒 Security Considerations

### Authentication
- JWT token-based authentication
- Token refresh mechanism
- Secure WebSocket connection

### Data Protection
- Local data encryption with Hive
- Secure media upload with signed URLs
- Input validation and sanitization

### Privacy
- Message encryption (future enhancement)
- User blocking functionality
- Message deletion options

## 📈 Performance Optimization

### Caching Strategy
- Local message cache with Hive
- Offline message queue
- Lazy loading for message history
- Image caching with CachedNetworkImage

### Network Optimization
- SignalR connection pooling
- Message batching for bulk operations
- Compressed media uploads
- Connection retry logic

## 🧪 Testing

### Unit Tests
```dart
// Test chat controller
test('should send message successfully', () async {
  final controller = ChatController();
  await controller.sendMessage(content: 'Test message');
  expect(controller.messages.length, 1);
});
```

### Widget Tests
```dart
// Test message bubble
testWidgets('should display message correctly', (tester) async {
  await tester.pumpWidget(MessageBubble(message: testMessage));
  expect(find.text('Test message'), findsOneWidget);
});
```

## 🚀 Future Enhancements

### Phase 2 Features
- [ ] Voice and video calls
- [ ] Message encryption
- [ ] Group chats
- [ ] Message reactions
- [ ] File sharing improvements
- [ ] Message search functionality

### Phase 3 Features
- [ ] Floating chat heads
- [ ] Chat bots integration
- [ ] Message translation
- [ ] Advanced media editing
- [ ] Chat analytics
- [ ] Message scheduling

## 🐛 Troubleshooting

### Common Issues

1. **SignalR Connection Failed**
   - Check network connectivity
   - Verify authentication token
   - Ensure backend SignalR hub is running

2. **Hive Generation Errors**
   - Run `flutter packages pub run build_runner clean`
   - Run `flutter packages pub run build_runner build`

3. **Media Upload Issues**
   - Check file permissions
   - Verify upload endpoint configuration
   - Ensure file size limits

4. **Push Notifications Not Working**
   - Verify FCM configuration
   - Check device token registration
   - Ensure notification permissions

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the API documentation
3. Check SignalR connection logs
4. Verify Hive database integrity

## 📄 License

This chat feature is part of the KrishiLink project and follows the same licensing terms. 