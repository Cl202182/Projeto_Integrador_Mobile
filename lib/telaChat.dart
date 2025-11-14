//pg alterada
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'image_service.dart';
import 'homeUser.dart'; // Para PerfilOngVisualizacaoUser
import 'perfil_user_visualizacao.dart'; // Para PerfilUserVisualizacao
import 'perfil_user_visualizacao_ong.dart'; // Para PerfilUserVisualizacaoOng

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
  late String userId;
  late String userType; // 'user' ou 'ong'
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Imagens de perfil
  String? userImageUrl;
  String? currentUserImageUrl;

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
    userId = args['userId'];
    userType =
        args['userType'] ?? 'ong'; // Default para ONG se não especificado
    _messagesRef =
        FirebaseDatabase.instance.ref().child('chats/$chatId/messages');

    // Carregar imagens de perfil
    _loadProfileImages();
  }

  Future<void> _loadProfileImages() async {
    try {
      // Carregar imagem do usuário atual - verificar se é ONG ou usuário
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('ongs')
          .doc(currentUserId)
          .get();

      if (currentUserDoc.exists) {
        // Usuário atual é ONG
        Map<String, dynamic> currentUserData =
            currentUserDoc.data() as Map<String, dynamic>;
        setState(() {
          currentUserImageUrl = currentUserData['imagemUrl'];
        });
      } else {
        // Usuário atual é usuário comum
        currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

        if (currentUserDoc.exists) {
          Map<String, dynamic> currentUserData =
              currentUserDoc.data() as Map<String, dynamic>;
          setState(() {
            currentUserImageUrl = currentUserData['imagemUrl'];
          });
        }
      }

      // Carregar imagem do outro usuário
      String collection = userType == 'ong' ? 'ongs' : 'users';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userImageUrl = userData['imagemUrl'];
        });
      }
    } catch (e) {
      print('Erro ao carregar imagens de perfil: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Função para proxy de imagens
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
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

  void _openProfile() async {
    // Detecta automaticamente se é ONG ou usuário verificando nas collections
    try {
      // Primeiro tenta buscar na collection 'ongs'
      DocumentSnapshot ongDoc =
          await FirebaseFirestore.instance.collection('ongs').doc(userId).get();

      if (ongDoc.exists) {
        // É uma ONG - usar PerfilOngVisualizacaoUser que tem postagens
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilOngVisualizacaoUser(
              ongId: userId,
              ongNome: userName,
            ),
          ),
        );
      } else {
        // Não é ONG, então é usuário - verificar se quem está vendo é ONG ou usuário
        String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
              .collection('ongs')
              .doc(currentUserId)
              .get();

          if (currentUserDoc.exists) {
            // Usuário atual é ONG, usar tela específica para ONGs
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerfilUserVisualizacaoOng(
                  userId: userId,
                  userName: userName,
                ),
              ),
            );
          } else {
            // Usuário atual é usuário comum
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PerfilUserVisualizacao(
                  userId: userId,
                  userName: userName,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar perfil: $e')),
      );
    }
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 1, 37, 54),
              ),
              child: ClipOval(
                child: SmartImage(
                  imageUrl: userImageUrl != null && userImageUrl!.isNotEmpty
                      ? _getProxiedImageUrl(userImageUrl!)
                      : '',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 1, 37, 54),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 1, 37, 54),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 1, 37, 54),
              ),
              child: ClipOval(
                child: SmartImage(
                  imageUrl: currentUserImageUrl != null &&
                          currentUserImageUrl!.isNotEmpty
                      ? _getProxiedImageUrl(currentUserImageUrl!)
                      : '',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 1, 37, 54),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 1, 37, 54),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
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
        title: GestureDetector(
          onTap: _openProfile,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: ClipOval(
                  child: SmartImage(
                    imageUrl: userImageUrl != null && userImageUrl!.isNotEmpty
                        ? _getProxiedImageUrl(userImageUrl!)
                        : '',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
                      'Toque para ver o perfil',
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _openProfile,
            tooltip: 'Ver perfil',
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

// Tela de visualização do perfil da ONG (já existente)
class PerfilVisualizacao extends StatefulWidget {
  final String ongId;
  final String ongName;

  const PerfilVisualizacao({
    super.key,
    required this.ongId,
    required this.ongName,
  });

  @override
  State<PerfilVisualizacao> createState() => _PerfilVisualizacaoState();
}

class _PerfilVisualizacaoState extends State<PerfilVisualizacao> {
  Map<String, dynamic>? ongData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosOng();
  }

  Future<void> _carregarDadosOng() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('ongs')
          .doc(widget.ongId)
          .get();

      if (doc.exists) {
        setState(() {
          ongData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _copiarParaClipboard(String texto, String tipo) async {
    await Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo copiado para a área de transferência'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
      ),
    );
  }

  void _mostrarDetalhesContato(String titulo, String conteudo, String tipo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conteudo),
              const SizedBox(height: 16),
              Text(
                'Toque em "Copiar" para copiar para a área de transferência.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                _copiarParaClipboard(conteudo, tipo);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 37, 54),
              ),
              child: const Text(
                'Copiar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String? content, IconData icon,
      {VoidCallback? onTap, Color? iconColor}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color.fromARGB(255, 1, 37, 54))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color.fromARGB(255, 1, 37, 54),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorarioFuncionamento() {
    if (ongData?['horarioFuncionamento'] == null)
      return const SizedBox.shrink();

    Map<String, String> horarios =
        Map<String, String>.from(ongData!['horarioFuncionamento']);

    // Remove horários vazios
    horarios.removeWhere((key, value) => value.isEmpty);

    if (horarios.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        const Color.fromARGB(255, 1, 37, 54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: Color.fromARGB(255, 1, 37, 54),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Horário de Funcionamento',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...horarios.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${_capitalize(entry.key)}:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasAtuacao() {
    if (ongData?['areasAtuacao'] == null) return const SizedBox.shrink();

    List<String> areas = List<String>.from(ongData!['areasAtuacao']);
    if (areas.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        const Color.fromARGB(255, 1, 37, 54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Color.fromARGB(255, 1, 37, 54),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Áreas de Atuação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas
                  .map((area) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 1, 37, 54)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromARGB(255, 1, 37, 54)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          area,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 1, 37, 54),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.ongName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 1, 37, 54),
              ),
            )
          : ongData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Perfil não encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header com foto e nome
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(255, 1, 37, 54),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ongData?['imagemUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(40),
                                      child: Image.network(
                                        ongData!['imagemUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              widget.ongName[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        widget.ongName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.ongName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 1, 37, 54),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (ongData?['email'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                ongData!['email'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informações
                      _buildInfoCard(
                        'Descrição',
                        ongData?['descricao'],
                        Icons.description,
                      ),

                      _buildInfoCard(
                        'Telefone',
                        ongData?['telefone'],
                        Icons.phone,
                        onTap: ongData?['telefone'] != null
                            ? () => _mostrarDetalhesContato(
                                'Telefone', ongData!['telefone'], 'Telefone')
                            : null,
                        iconColor: Colors.green[600],
                      ),

                      _buildInfoCard(
                        'WhatsApp',
                        ongData?['whatsapp'],
                        Icons.chat,
                        onTap: ongData?['whatsapp'] != null
                            ? () => _mostrarDetalhesContato(
                                'WhatsApp', ongData!['whatsapp'], 'WhatsApp')
                            : null,
                        iconColor: Colors.green[700],
                      ),

                      _buildInfoCard(
                        'Endereço',
                        ongData?['endereco'],
                        Icons.location_on,
                        onTap: ongData?['endereco'] != null
                            ? () => _mostrarDetalhesContato(
                                'Endereço', ongData!['endereco'], 'Endereço')
                            : null,
                        iconColor: Colors.red[600],
                      ),

                      _buildInfoCard(
                        'Site',
                        ongData?['site'],
                        Icons.web,
                        onTap: ongData?['site'] != null
                            ? () => _mostrarDetalhesContato(
                                'Site', ongData!['site'], 'Site')
                            : null,
                        iconColor: Colors.blue[600],
                      ),

                      _buildInfoCard(
                        'Instagram',
                        ongData?['instagram'] != null
                            ? '@${ongData!['instagram'].replaceAll('@', '')}'
                            : null,
                        Icons.camera_alt,
                        onTap: ongData?['instagram'] != null
                            ? () => _mostrarDetalhesContato(
                                'Instagram',
                                '@${ongData!['instagram'].replaceAll('@', '')}',
                                'Instagram')
                            : null,
                        iconColor: Colors.purple[600],
                      ),

                      _buildInfoCard(
                        'Facebook',
                        ongData?['facebook'],
                        Icons.facebook,
                        onTap: ongData?['facebook'] != null
                            ? () => _mostrarDetalhesContato(
                                'Facebook', ongData!['facebook'], 'Facebook')
                            : null,
                        iconColor: Colors.blue[800],
                      ),

                      // Áreas de atuação
                      _buildAreasAtuacao(),

                      // Horário de funcionamento
                      _buildHorarioFuncionamento(),

                      const SizedBox(height: 20),

                      // Botão de voltar ao chat
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'Voltar ao Chat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 37, 54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}

// Nova classe para visualização do perfil do usuário
class PerfilUsuarioVisualizacao extends StatefulWidget {
  final String userId;
  final String userName;

  const PerfilUsuarioVisualizacao({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PerfilUsuarioVisualizacao> createState() =>
      _PerfilUsuarioVisualizacaoState();
}

class _PerfilUsuarioVisualizacaoState extends State<PerfilUsuarioVisualizacao> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> _copiarParaClipboard(String texto, String tipo) async {
    await Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tipo copiado para a área de transferência'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
      ),
    );
  }

  void _mostrarDetalhesContato(String titulo, String conteudo, String tipo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conteudo),
              const SizedBox(height: 16),
              Text(
                'Toque em "Copiar" para copiar para a área de transferência.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                _copiarParaClipboard(conteudo, tipo);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 37, 54),
              ),
              child: const Text(
                'Copiar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String? content, IconData icon,
      {VoidCallback? onTap, Color? iconColor}) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color.fromARGB(255, 1, 37, 54))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color.fromARGB(255, 1, 37, 54),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreasInteresse() {
    if (userData?['areasInteresse'] == null) return const SizedBox.shrink();

    List<String> areas = List<String>.from(userData!['areasInteresse']);
    if (areas.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        const Color.fromARGB(255, 1, 37, 54).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color.fromARGB(255, 1, 37, 54),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Áreas de Interesse',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas
                  .map((area) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 1, 37, 54)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromARGB(255, 1, 37, 54)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          area,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 1, 37, 54),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarDataCadastro(dynamic timestamp) {
    if (timestamp == null) return 'Data não informada';

    try {
      if (timestamp is Timestamp) {
        DateTime data = timestamp.toDate();
        return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      }
      return 'Data não informada';
    } catch (e) {
      return 'Data não informada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 1, 37, 54),
              ),
            )
          : userData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Perfil não encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header com foto e nome
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(255, 1, 37, 54),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 1, 37, 54),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (userData?['email'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                userData!['email'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informações pessoais
                      _buildInfoCard(
                        'CPF',
                        userData?['cpf']?.isNotEmpty == true
                            ? userData!['cpf']
                            : null,
                        Icons.credit_card,
                        onTap: userData?['cpf']?.isNotEmpty == true
                            ? () => _mostrarDetalhesContato(
                                'CPF', userData!['cpf'], 'CPF')
                            : null,
                      ),

                      _buildInfoCard(
                        'Telefone',
                        userData?['telefone']?.isNotEmpty == true
                            ? userData!['telefone']
                            : null,
                        Icons.phone,
                        onTap: userData?['telefone']?.isNotEmpty == true
                            ? () => _mostrarDetalhesContato(
                                'Telefone', userData!['telefone'], 'Telefone')
                            : null,
                        iconColor: Colors.green[600],
                      ),

                      _buildInfoCard(
                        'Data de Nascimento',
                        userData?['dataNascimento']?.isNotEmpty == true
                            ? userData!['dataNascimento']
                            : null,
                        Icons.cake,
                      ),

                      _buildInfoCard(
                        'Endereço',
                        userData?['endereco']?.isNotEmpty == true
                            ? userData!['endereco']
                            : null,
                        Icons.location_on,
                        onTap: userData?['endereco']?.isNotEmpty == true
                            ? () => _mostrarDetalhesContato(
                                'Endereço', userData!['endereco'], 'Endereço')
                            : null,
                        iconColor: Colors.red[600],
                      ),

                      _buildInfoCard(
                        'CEP',
                        userData?['cep']?.isNotEmpty == true
                            ? userData!['cep']
                            : null,
                        Icons.location_city,
                        onTap: userData?['cep']?.isNotEmpty == true
                            ? () => _mostrarDetalhesContato(
                                'CEP', userData!['cep'], 'CEP')
                            : null,
                      ),

                      // Áreas de interesse
                      _buildAreasInteresse(),

                      // Data de cadastro
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 1, 37, 54)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Color.fromARGB(255, 1, 37, 54),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Membro desde',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 1, 37, 54),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatarDataCadastro(
                                        userData?['created_at']),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botão de voltar ao chat
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'Voltar ao Chat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 37, 54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}
