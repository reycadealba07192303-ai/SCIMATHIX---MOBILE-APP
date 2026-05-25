import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:scimathix/data/services/api_service.dart';

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  late IO.Socket socket;
  
  void initSocket() {
    socket = IO.io(ApiService.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    socket.connect();
    
    socket.onConnect((_) {
      print('Connected to Socket.IO');
    });
    
    socket.onDisconnect((_) {
      print('Disconnected from Socket.IO');
    });
  }
  
  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }
  
  void off(String event) {
    socket.off(event);
  }
  
  void disconnect() {
    socket.disconnect();
  }
}
