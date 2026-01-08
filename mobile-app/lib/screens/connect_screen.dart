import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'home_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController =
      TextEditingController(text: '5000');

  bool isConnecting = false;
  String errorText = '';

  Future<void> _connect() async {
    setState(() {
      isConnecting = true;
      errorText = '';
    });

    final ip = ipController.text.trim();
    final port = int.tryParse(portController.text.trim());

    if (ip.isEmpty || port == null) {
      setState(() {
        errorText = 'Invalid IP or Port';
        isConnecting = false;
      });
      return;
    }

    // 🔑 SET GLOBAL SOCKET CONFIG
    SocketService.serverIp = ip;
    SocketService.serverPort = port;

    final socketService = SocketService();

    try {
      final res = await socketService.sendCommand('0');
      if (res.trim() == 'PONG') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(),
          ),
        );
      } else {
        throw Exception();
      }
    } catch (_) {
      setState(() {
        errorText = 'Unable to connect to server';
        isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security,
                    size: 60, color: Colors.cyanAccent),
                const SizedBox(height: 12),
                const Text(
                  'Server Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                _inputField(
                  controller: ipController,
                  label: 'Server IP',
                  hint: '192.168.0.104',
                  icon: Icons.language,
                ),
                const SizedBox(height: 16),

                _inputField(
                  controller: portController,
                  label: 'Port',
                  hint: '5000',
                  icon: Icons.settings_ethernet,
                  keyboard: TextInputType.number,
                ),

                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(errorText,
                      style:
                          const TextStyle(color: Colors.redAccent)),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isConnecting ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isConnecting
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            'CONNECT',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
