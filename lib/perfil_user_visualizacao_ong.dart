//pg alterada
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PerfilUserVisualizacaoOng extends StatefulWidget {
  final String userId;
  final String userName;

  const PerfilUserVisualizacaoOng({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<PerfilUserVisualizacaoOng> createState() =>
      _PerfilUserVisualizacaoOngState();
}

class _PerfilUserVisualizacaoOngState extends State<PerfilUserVisualizacaoOng> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? currentOngId;
  String? currentOngName;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
    _carregarDadosOng();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e')),
        );
      }
    }
  }

  Future<void> _carregarDadosOng() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            currentOngId = uid;
            currentOngName = dados['nome'] ?? 'ONG';
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar dados da ONG: $e');
    }
  }

  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  Future<void> _iniciarChat() async {
    if (currentOngId == null || currentOngName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar dados da ONG'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String chatId = _generateChatId(currentOngId!, widget.userId);

      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'userName': widget.userName,
          'userId': widget.userId,
          'currentUserId': currentOngId,
          'currentUserName': currentOngName,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateChatId(String id1, String id2) {
    return (id1.hashCode <= id2.hashCode) ? '${id1}_$id2' : '${id2}_$id1';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            onPressed: _iniciarChat,
            tooltip: 'Iniciar Chat',
          ),
        ],
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
                            _buildImagemPerfil(),
                            const SizedBox(height: 16),
                            Text(
                              userData?['nome'] ?? widget.userName,
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

                      // Botão de Chat em destaque
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _iniciarChat,
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'Iniciar Conversa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 37, 54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informações do usuário
                      if (userData?['descricao'] != null)
                        _buildInfoCard(
                          'Descrição',
                          userData!['descricao'],
                          Icons.description,
                        ),
                      if (userData?['telefone'] != null)
                        _buildInfoCard(
                          'Telefone',
                          userData!['telefone'],
                          Icons.phone,
                        ),
                      if (userData?['whatsapp'] != null)
                        _buildInfoCard(
                          'WhatsApp',
                          userData!['whatsapp'],
                          Icons.chat,
                        ),
                      if (userData?['endereco'] != null)
                        _buildInfoCard(
                          'Endereço',
                          userData!['endereco'],
                          Icons.location_on,
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagemPerfil() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromARGB(255, 1, 37, 54),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: (userData?['imagemUrl'] != null &&
                userData!['imagemUrl'].toString().isNotEmpty)
            ? Image.network(
                _getProxiedImageUrl(userData!['imagemUrl']),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color.fromARGB(255, 1, 37, 54),
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 40,
                    color: Color.fromARGB(255, 1, 37, 54),
                  );
                },
              )
            : const Icon(
                Icons.person,
                size: 40,
                color: Color.fromARGB(255, 1, 37, 54),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String? content, IconData icon) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 1, 37, 54).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color.fromARGB(255, 1, 37, 54),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color.fromARGB(255, 1, 37, 54),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 1, 37, 54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatarData(dynamic timestamp) {
    if (timestamp == null) return 'Não informado';
    try {
      if (timestamp is Timestamp) {
        DateTime data = timestamp.toDate();
        return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      }
      return 'Não informado';
    } catch (e) {
      return 'Não informado';
    }
  }
}
