import 'dart:async';
import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'connect_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String resultText = 'Awaiting command...';
  bool isServerConnected = false;
  bool hasNewAlert = false;

  String _lastAlert = '';
  Timer? _alertTimer;

  final ScrollController _scrollController = ScrollController();
  final SocketService socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _startAlertPolling();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= AUTO SCROLL =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= SAFE COMMAND HANDLER =================
  void _handleCommand(Future<void> Function() action) {
    if (!isServerConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Server not connected'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    action();
  }

  // ================= CONFIRM ACTION =================
  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  // ================= PING =================
  Future<bool> _pingServer() async {
    try {
      final res = await socketService.sendCommand('0');
      return res.trim() == 'PONG';
    } catch (_) {
      return false;
    }
  }

  // ================= ALERT POLLING =================
  void _startAlertPolling() {
    _alertTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      final alive = await _pingServer();
      setState(() => isServerConnected = alive);

      if (!alive) return;

      try {
        final alert = await socketService.sendCommand('11');
        if (alert.isNotEmpty && alert != _lastAlert) {
          _lastAlert = alert;
          hasNewAlert = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                content: const Text('⚠ New system alert received'),
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  // ================= SEND COMMAND =================
  Future<void> _sendCommand(String command, String loadingText) async {
    setState(() => resultText = loadingText);
    _scrollToBottom();

    try {
      final res = await socketService.sendCommand(command);
      setState(() {
        isServerConnected = true;
        resultText = res;
      });
    } catch (_) {
      setState(() {
        isServerConnected = false;
        resultText = '❌ Server not reachable';
      });
    }
    _scrollToBottom();
  }

  // ================= QUICK SUMMARY =================
  Future<void> _quickSummary() async {
    setState(() => resultText = 'Fetching system summary...');
    _scrollToBottom();

    try {
      final uptime = await socketService.sendCommand('9');
      final cpu = await socketService.sendCommand('1');
      final ram = await socketService.sendCommand('2');
      final disk = await socketService.sendCommand('8');

      setState(() {
        resultText =
            '===== SYSTEM SUMMARY =====\n\n'
            '$uptime\n\n$cpu\n$ram\n\n$disk';
      });
    } catch (_) {
      setState(() => resultText = '❌ Server not reachable');
    }
    _scrollToBottom();
  }

  // ================= DISCONNECT =================
  void _disconnect() {
    _confirmAction(
      title: 'Disconnect',
      message: 'Do you want to disconnect from this server?',
      onConfirm: () {
        _alertTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConnectScreen()),
        );
      },
    );
  }

  // ================= ALERT VIEW =================
  void _openAlert() {
    if (_lastAlert.isEmpty) {
      _showInfoDialog('Alerts', 'No alerts found');
      return;
    }

    hasNewAlert = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF020617),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SYSTEM ALERT',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lastAlert,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('CLOSE', style: TextStyle(color: Colors.cyan)),
              ),
            ),
          ],
        ),
      ),
    );

    setState(() => resultText = '⚠ ALERT:\n$_lastAlert');
    _scrollToBottom();
  }

  void _showInfoDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.cyan)),
          )
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 5, 24),
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              'SERVER CONSOLE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700,color: Color.fromARGB(255, 207, 108, 108),),
            ),

          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Disconnect',
            onPressed: _disconnect,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
          IconButton(
            onPressed: _openAlert,
            icon: Stack(
              children: [
                const Icon(Icons.notifications_active,
                    color: Colors.cyanAccent),
                if (hasNewAlert)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _serverStatusCard(),
            const SizedBox(height: 24),

            _sectionCard('SYSTEM OVERVIEW', [
              _gridBtn(Icons.dashboard, 'SUMMARY', Colors.cyan,
                  () => _handleCommand(_quickSummary)),
              _gridBtn(Icons.timer, 'UPTIME', Colors.teal,
                  () => _handleCommand(
                      () => _sendCommand('9', 'Fetching uptime...'))),
              _gridBtn(Icons.computer, 'OS INFO', Colors.indigo,
                  () => _handleCommand(
                      () => _sendCommand('10', 'Fetching OS info...'))),
              _gridBtn(Icons.storage, 'DISK', Colors.deepPurple,
                  () => _handleCommand(
                      () => _sendCommand('8', 'Fetching disk...'))),
            ]),

            _sectionCard('LIVE MONITORING', [
              _gridBtn(Icons.memory, 'CPU', Colors.orange,
                  () => _handleCommand(
                      () => _sendCommand('1', 'Fetching CPU...'))),
              _gridBtn(Icons.storage, 'RAM', Colors.green,
                  () => _handleCommand(
                      () => _sendCommand('2', 'Fetching RAM...'))),
              _gridBtn(Icons.battery_full, 'BATTERY', Colors.blueGrey,
                  () => _handleCommand(
                      () => _sendCommand('3', 'Fetching battery...'))),
              _gridBtn(Icons.apps, 'RUNNING', Colors.grey,
                  () => _handleCommand(
                      () => _sendCommand('4', 'Fetching apps...'))),
            ]),

            _sectionCard('PC CONTROLS', [
              _gridBtn(Icons.lock, 'LOCK', Colors.blueGrey, () {
                _confirmAction(
                  title: 'Lock PC',
                  message: 'Are you sure you want to lock this PC?',
                  onConfirm: () =>
                      _sendCommand('5', 'Locking PC...'),
                );
              }),
              _gridBtn(Icons.restart_alt, 'RESTART', Colors.deepOrange, () {
                _confirmAction(
                  title: 'Restart PC',
                  message:
                      'Are you sure you want to restart this PC?',
                  onConfirm: () =>
                      _sendCommand('7', 'Restarting PC...'),
                );
              }),
              _gridBtn(Icons.power_settings_new, 'SHUTDOWN', Colors.red, () {
                _confirmAction(
                  title: 'Shutdown PC',
                  message:
                      'Are you sure you want to shutdown this PC?',
                  onConfirm: () =>
                      _sendCommand('6', 'Shutting down PC...'),
                );
              }),
            ]),

            _terminalCard(),
          ],
        ),
      ),
    );
  }

  // ================= STATUS CARD =================
  Widget _serverStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isServerConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isServerConnected ? 'CONNECTED' : 'DISCONNECTED',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> buttons) {
    return Card(
      color: const Color(0xFF020617),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionTitle(title),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: buttons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _terminalCard() {
    return Card(
      color: const Color(0xFF020617),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('SERVER RESPONSE'),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                child: Text(
                  resultText,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _gridBtn(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
