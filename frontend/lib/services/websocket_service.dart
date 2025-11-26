import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  String? _currentUrl;
  
  Stream<Map<String, dynamic>> get messageStream => 
      _messageController?.stream ?? Stream.empty();
  
  bool get isConnected => _channel != null;
  
  Future<void> connect(String url) async {
    try {
      if (_channel != null) {
        await disconnect();
      }
      
      _currentUrl = url;
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _messageController?.add(data);
          } catch (e) {
            debugPrint('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleConnectionError();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleConnectionClosed();
        },
      );
      
      debugPrint('WebSocket connected to: $url');
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      rethrow;
    }
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        debugPrint('Error sending WebSocket message: $e');
      }
    } else {
      debugPrint('WebSocket not connected');
    }
  }
  
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    if (_messageController != null) {
      await _messageController!.close();
      _messageController = null;
    }
    
    _currentUrl = null;
    debugPrint('WebSocket disconnected');
  }
  
  void _handleConnectionError() {
    // Attempt to reconnect after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentUrl != null) {
        debugPrint('Attempting to reconnect WebSocket...');
        connect(_currentUrl!);
      }
    });
  }
  
  void _handleConnectionClosed() {
    _channel = null;
    if (_messageController != null && !_messageController!.isClosed) {
      _messageController!.close();
    }
  }
}

class ChatWebSocketService extends WebSocketService {
  String? _productId;
  
  Future<void> connectToProductChat(String productId) async {
    _productId = productId;
    const baseUrl = kIsWeb ? 'ws://127.0.0.1:8000' : 'ws://10.0.2.2:8000';
    final url = '$baseUrl/ws/chat/$productId/';
    await connect(url);
  }
  
  void sendChatMessage({
    required String message,
    required String senderId,
    required String receiverId,
  }) {
    sendMessage({
      'message': message,
      'sender_id': senderId,
      'receiver_id': receiverId,
    });
  }
}

class NotificationWebSocketService extends WebSocketService {
  Future<void> connectToUserNotifications(String userId) async {
    const baseUrl = kIsWeb ? 'ws://127.0.0.1:8000' : 'ws://10.0.2.2:8000';
    final url = '$baseUrl/ws/notifications/$userId/';
    await connect(url);
  }
  
  void markNotificationRead(String notificationId) {
    sendMessage({
      'type': 'mark_read',
      'notification_id': notificationId,
    });
  }
}
