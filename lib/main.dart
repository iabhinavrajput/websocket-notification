import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'websocket_channel',
        channelName: 'WebSocket Notifications',
        channelDescription: 'Receive notifications via WebSocket',
        defaultColor: Colors.deepPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late IOWebSocketChannel? channel;
  List<Map<String, String>> notifications = [];
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    connectToWebSocket();
  }

  // Show Notification
  Future<void> showNotification(String title, String message) async {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'websocket_channel',
        title: title,
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void connectToWebSocket() {
    try {
      print("Connecting to WebSocket...");
      setState(() => isConnected = false);

      // channel = IOWebSocketChannel.connect('ws://lcalmachine ip:8080'); // here will come the IP of your server or your lcalmachine ip with port 8080


      channel!.stream.listen((message) {
        print("Received from WebSocket: $message");

        final data = json.decode(message);
        setState(() {
          notifications.insert(0, {'title': data['title'], 'message': data['message']});
          isConnected = true;
        });

        // Show Notification
        showNotification(data['title'], data['message']);
      }, onError: (error) {
        print("WebSocket Error: $error");
        setState(() => isConnected = false);
      }, onDone: () {
        print("WebSocket connection closed.");
        setState(() => isConnected = false);
      });
    } catch (e) {
      print("WebSocket Connection Failed: $e");
      setState(() => isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("WebSocket Notifications")),
        body: Column(
          children: [
            // Connection Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: isConnected ? Colors.green : Colors.red,
              child: Text(
                isConnected ? "Connected to WebSocket" : "Disconnected - Tap to Reconnect",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            
            // Notification List
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text("No notifications yet!", style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(notifications[index]['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(notifications[index]['message']!),
                            leading: const Icon(Icons.notifications_active, color: Colors.deepPurple),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // Floating Action Button (Reconnect)
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: connectToWebSocket,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }
}
