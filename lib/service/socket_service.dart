import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  Future<void> connect() async {
    if (socket != null && socket!.connected) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final token = await user.getIdToken(true);
    
    socket = IO.io(AppConstants.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Web
      .setAuth({'token': token})
      .enableAutoConnect()
      .build());

    socket!.onConnect((_) {
      print('--> Connected to Socket.IO');
    });

    socket!.onDisconnect((_) {
      print('--> Disconnected from Socket.IO');
    });
    
    socket!.onConnectError((data) {
      print('--> Connect Error: $data');
    });
  }

  void joinRide(String rideId) {
    socket?.emit('join_ride', rideId);
  }

  void leaveRide(String rideId) {
    socket?.emit('leave_ride', rideId);
  }

  void sendMessage(String rideId, String text) {
    socket?.emit('CHAT:SEND_MESSAGE', {'rideId': rideId, 'text': text});
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    socket?.off(event, handler);
  }

  void onConnect(Function(dynamic) handler) {
    socket?.onConnect(handler);
  }

  void disconnect() {
    socket?.disconnect();
  }
}
