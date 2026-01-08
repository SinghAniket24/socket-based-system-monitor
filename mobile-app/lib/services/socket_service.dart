import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class SocketService {
  static String serverIp = '0.0.0.0';
  static int serverPort = 5000;

  Future<String> sendCommand(String command) async {
    try {
      final socket = await Socket.connect(
        serverIp,
        serverPort,
        timeout: const Duration(seconds: 5),
      );

      socket.write('$command\n');
      await socket.flush();

      StringBuffer buffer = StringBuffer();

      await for (Uint8List data in socket) {
        buffer.write(utf8.decode(data));
        if (buffer.toString().contains('\n')) break;
      }

      socket.destroy();
      return buffer.toString().trim();
    } catch (e) {
      return 'Error: Unable to connect to server';
    }
  }
}
