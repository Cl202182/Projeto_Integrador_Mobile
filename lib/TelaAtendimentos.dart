//pg alterada
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_projeto_integrador/utils/chat_utils.dart';
import 'components/bottom_nav_bar.dart';
import 'image_service.dart';

class Atendimento extends StatefulWidget {
  const Atendimento({super.key});

  @override
  State<Atendimento> createState() => _AtendimentoState();
}

class _AtendimentoState extends State<Atendimento> {
  final String currentOngId = FirebaseAuth.instance.currentUser!.uid;
  String? currentOngName;
  String? currentOngEmail;
  String? ongImageUrl;
  late DatabaseReference _chatsRef;

  @override
  void initState() {
    super.initState();
    _chatsRef = FirebaseDatabase.instance.ref().child('chats');
    _loadCurrentOngData();
  }

  // Função para proxy de imagens
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  Future<void> _loadCurrentOngData() async {
    try {
      // Busca primeiro na collection 'ongs'
      DocumentSnapshot ongDoc = await FirebaseFirestore.instance
          .collection('ongs')
          .doc(currentOngId)
          .get();

      if (ongDoc.exists) {
        final ongData = ongDoc.data() as Map<String, dynamic>;
        setState(() {
          currentOngName = ongData['nome'] ?? ongData['name'] ?? 'ONG';
          currentOngEmail = ongData['email'] ?? '';
          ongImageUrl = ongData['imagemUrl'];
        });
      } else {
        // Se não encontrar em 'ongs', tenta em 'users'
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentOngId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            currentOngName = userData['nome'] ?? userData['name'] ?? 'ONG';
            currentOngEmail = userData['email'] ?? '';
            ongImageUrl = userData['imagemUrl'];
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar dados da ONG: $e');
      setState(() {
        currentOngName = 'ONG';
        currentOngEmail = '';
      });
    }
  }

  // Função para extrair IDs de usuários das conversas em tempo real
  List<String> _extractConversedUserIds(DatabaseEvent event) {
    Set<String> userIds = {};

    if (event.snapshot.exists) {
      final chatsData = Map<String, dynamic>.from(event.snapshot.value as Map);

      for (String chatId in chatsData.keys) {
        // Verifica se o chatId contém o currentOngId
        if (chatId.contains(currentOngId) && chatId.contains('_')) {
          final parts = chatId.split('_');
          if (parts.length == 2) {
            // Encontra o outro participante
            final otherUserId = parts[0] == currentOngId ? parts[1] : parts[0];
            if (otherUserId != currentOngId) {
              // Verifica se realmente existem mensagens neste chat
              final chatData = chatsData[chatId];
              if (chatData != null && chatData['messages'] != null) {
                userIds.add(otherUserId);
              }
            }
          }
        }
      }
    }

    print('IDs de usuários encontrados em tempo real: $userIds'); // Debug
    return userIds.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Atendimentos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header com ONG conectada
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 1, 37, 54),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(22.5),
                    ),
                    child: Center(
                      child: Text(
                        currentOngName != null && currentOngName!.isNotEmpty
                            ? currentOngName![0].toUpperCase()
                            : 'O',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conectado como:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentOngName ?? 'Carregando...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (currentOngEmail != null &&
                            currentOngEmail!.isNotEmpty)
                          Text(
                            currentOngEmail!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de atendimentos existentes em tempo real
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatsRef.onValue,
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar atendimentos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!chatSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
                  );
                }

                // Extrai IDs dos usuários com conversas
                final conversedUserIds =
                    _extractConversedUserIds(chatSnapshot.data!);

                if (conversedUserIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum atendimento ainda',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seus atendimentos aparecerão aqui',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // StreamBuilder para buscar dados dos usuários
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId,
                          whereIn: conversedUserIds.isEmpty
                              ? ['dummy']
                              : conversedUserIds)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Erro ao carregar dados dos usuários',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!userSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      );
                    }

                    final users = userSnapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData =
                            users[index].data() as Map<String, dynamic>;
                        final userId = users[index].id;
                        final userName = userData['nome'] ??
                            userData['name'] ??
                            'Usuário sem nome';
                        final userEmail = userData['email'] ?? '';
                        final userPhone =
                            userData['telefone'] ?? userData['phone'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                String chatId = ChatUtils.generateChatId(
                                    currentOngId, userId);

                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: {
                                    'chatId': chatId,
                                    'userName': userName,
                                    'userId': userId,
                                    'userType': 'user',
                                    'currentUserId': currentOngId,
                                    'currentUserName': currentOngName,
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Status de atendimento
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Avatar com imagem de perfil
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: userData['imagemUrl'] != null &&
                                              userData['imagemUrl']
                                                  .toString()
                                                  .isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              child: SmartImage(
                                                imageUrl: _getProxiedImageUrl(
                                                    userData['imagemUrl']),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                placeholder: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[600],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      userName.isNotEmpty
                                                          ? userName[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[600],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      userName.isNotEmpty
                                                          ? userName[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                userName.isNotEmpty
                                                    ? userName[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Informações do usuário
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromARGB(
                                                  255, 1, 37, 54),
                                            ),
                                          ),
                                          if (userPhone.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              userPhone,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ] else if (userEmail.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              userEmail,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Ícone de chat
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            const Color.fromARGB(255, 1, 37, 54)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble,
                                        color: Color.fromARGB(255, 1, 37, 54),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        isOng: true,
        profileImageUrl: ongImageUrl,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
