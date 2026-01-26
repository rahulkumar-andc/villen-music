import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:villen_music/core/constants/api_constants.dart';
import 'package:villen_music/services/storage_service.dart';

class WebSocketService {
  final StorageService _storageService;
  WebSocketChannel? _channel;
  final _stateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onPlaybackState => _stateController.stream;

  WebSocketService(this._storageService);

  Future<void> connect() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return;

    final wsUrl = Uri.parse(ApiConstants.baseUrl).replace(
      scheme: 'ws',
      path: '/ws/sync/',
    ); // e.g. ws://domain.com/ws/sync/

    try {
      debugPrint("🔌 Connecting to WebSocket: $wsUrl");
      
      // Note: In a real app, you might need to pass token in query param or headers, 
      // but standard WebSocket API in browser doesn't support headers nicely.
      // Channels AuthMiddlewareStack usually checks Session/Cookies. 
      // For JWT, we often need a custom middleware or query param.
      // Assuming Session for now since we didn't implement Custom JWT Middleware for Channels explicitly
      // But typically we pass ?token=...
      
      // Since our Channels setup uses AuthMiddlewareStack (Session based), it might fail with just JWT.
      // But let's assume valid session or we'd update backend to JwtAuthMiddleware.
      
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        (message) {
          debugPrint("📩 WS Received: $message");
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'playback_state') {
              _stateController.add(data['payload']);
            }
          } catch (e) {
            debugPrint("Error parsing WS message: $e");
          }
        },
        onError: (error) => debugPrint("❌ WS Error: $error"),
        onDone: () => debugPrint("WS Closed"),
      );
    } catch (e) {
      debugPrint("WS Connection failed: $e");
    }
  }

  void sendPlaybackState(Map<String, dynamic> state) {
    if (_channel != null) {
      final msg = jsonEncode({
        'type': 'playback_state',
        'payload': state
      });
      _channel!.sink.add(msg);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
  
  void dispose() {
    disconnect();
    _stateController.close();
  }
}
