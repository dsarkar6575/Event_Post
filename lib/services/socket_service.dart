import 'dart:async';
import 'package:myapp/models/message_model.dart'; // Ensure this path is correct
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  final _messageStreamController = StreamController<Message>.broadcast();
  Stream<Message> get messageStream => _messageStreamController.stream;
  

  void connect(String token) {
    print("--- ATTEMPTING TO CONNECT WITH TOKEN: $token ---");
    if (_socket?.connected ?? false) {
      print("Socket already connected.");
      return;
    }

    // Use your backend URL
    const String socketUrl = 'https://event-backend-5dbb.onrender.com';

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token} // Pass JWT token for authentication
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ SOCKET CONNECTED');
      _socket!.on('receiveMessage', (data) {
        print('📩 MESSAGE RECEIVED: $data');
        _messageStreamController.add(Message.fromJson(data));
      });
    });

    _socket!.onConnectError((data) => print('❌ SOCKET CONNECT ERROR: $data'));
    _socket!.onError((data) => print('❌ SOCKET ERROR: $data'));
    _socket!.onDisconnect((_) => print('⚠️ SOCKET DISCONNECTED'));
  }

  void sendMessage({
    required String chatRoomId,
    required String content,
    required MessageType type,
  }) {
    if (_socket == null || !_socket!.connected) {
      print('Cannot send message, socket is not connected.');
      return;
    }
    _socket!.emit('sendMessage', {
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last,
    });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}