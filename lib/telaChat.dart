import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TelaChat extends StatefulWidget {
  const TelaChat({super.key});

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseReference _messagesRef;
  late String chatId;
  late String userName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    chatId = args['chatId'];
    userName = args['userName'];
    _messagesRef =
        FirebaseDatabase.instance.ref().child('chats/$chatId/messages');
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'senderId': currentUserId,
      'text': _messageController.text.trim(),
      'timestamp': ServerValue.timestamp,
    };

    _messagesRef.push().set(message);
    _messageController.clear();
  }

  String _formatTimestamp(int timestamp) {
    return DateFormat('HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat com $userName'),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Nenhuma mensagem ainda."));
                }

                final messagesMap = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );

                final messages = messagesMap.entries.map((entry) {
                  final msg = Map<String, dynamic>.from(entry.value);
                  msg['key'] = entry.key;
                  return msg;
                }).toList()
                  ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message['timestamp']),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Color.fromARGB(255, 1, 37, 54)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
