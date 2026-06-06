import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:scimathix/core/utils/app_logger.dart';
import 'package:scimathix/data/services/api_service.dart';

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  io.Socket? _socket;
  
  void initSocket() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    _socket = io.io(ApiService.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
    });
    
    _socket!.connect();
    
    _socket!.onConnect((_) {
      AppLogger.info('Connected to Socket.IO');
    });
    
    _socket!.onDisconnect((_) {
      AppLogger.info('Disconnected from Socket.IO');
    });

    _socket!.onReconnect((_) {
      AppLogger.info('Reconnected to Socket.IO');
    });

    _socket!.onReconnectError((_) {
      AppLogger.warning('Socket.IO reconnection error');
    });
  }
  
  void on(String event, Function(dynamic) callback) {
    initSocket();
    _socket!.on(event, callback);
  }
  
  void off(String event, [Function(dynamic)? callback]) {
    if (callback != null) {
      _socket?.off(event, callback);
    } else {
      _socket?.off(event);
    }
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
