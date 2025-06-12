import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TelaChat extends StatefulWidget {
  const TelaChat({super.key});

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseReference _messagesRef;
  late String chatId;
  late String userName;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    chatId = args['chatId'];
    userName = args['userName'];
    _messagesRef =
        FirebaseDatabase.instance.ref().child('chats/$chatId/messages');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  String _formatTimestamp(int timestamp) {
    return DateFormat('HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color.fromARGB(255, 1, 37, 54),
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color.fromARGB(255, 1, 37, 54)
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(message['timestamp']),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color.fromARGB(255, 1, 37, 54),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 1, 37, 54).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _messagesRef.orderByChild('timestamp').onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 1, 37, 54)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Color.fromARGB(255, 1, 37, 54),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Nenhuma mensagem ainda",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 1, 37, 54),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Inicie a conversa enviando uma mensagem!",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
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

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            hintStyle: TextStyle(color: Colors.black54),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 1, 37, 54),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 1, 37, 54)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
