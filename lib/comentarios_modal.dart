//pg alterada
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_service.dart';
import 'homeUser.dart'; // Para PerfilOngVisualizacaoUser
import 'perfil_user_visualizacao.dart'; // Para PerfilUserVisualizacao

// Modal para comentários das ONGs
class ComentariosModal extends StatefulWidget {
  final String postId;
  final String ongNome;

  const ComentariosModal({
    super.key,
    required this.postId,
    required this.ongNome,
  });

  @override
  State<ComentariosModal> createState() => _ComentariosModalState();
}

class _ComentariosModalState extends State<ComentariosModal> {
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviandoComentario = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    setState(() {
      _enviandoComentario = true;
    });

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Buscar dados da ONG
      DocumentSnapshot ongDoc =
          await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

      String ongName = 'ONG';
      String? ongImagemUrl;
      if (ongDoc.exists) {
        Map<String, dynamic> ongData = ongDoc.data() as Map<String, dynamic>;
        ongName = ongData['nome'] ?? 'ONG';
        ongImagemUrl = ongData['imagemUrl'];
      }

      // Adicionar comentário
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comentarios')
          .add({
        'texto': _comentarioController.text.trim(),
        'autorId': uid,
        'autorNome': ongName,
        'autorTipo': 'ong',
        'autorImagemUrl': ongImagemUrl,
        'created_at': FieldValue.serverTimestamp(),
      });

      _comentarioController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comentário enviado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar comentário: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _enviandoComentario = false;
      });
    }
  }

  String _formatarTempoComentario(Timestamp? timestamp) {
    if (timestamp == null) return 'Agora';

    final now = DateTime.now();
    final commentTime = timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${commentTime.day}/${commentTime.month}/${commentTime.year}';
    }
  }

  // Função para navegar para o perfil
  void _verPerfil(String autorId, String autorNome, String autorTipo) {
    if (autorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil não disponível'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar se não é o próprio usuário
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == autorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode visualizar seu próprio perfil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context); // Fecha o modal primeiro

    if (autorTipo == 'user') {
      // Para usuários, navegar para perfil público
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilUserVisualizacao(
            userId: autorId,
            userName: autorNome,
          ),
        ),
      );
    } else if (autorTipo == 'ong') {
      // Para ONGs, navegar para perfil da ONG
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilOngVisualizacaoUser(
            ongId: autorId,
            ongNome: autorNome,
          ),
        ),
      );
    }
  }

  Widget _buildComentario(DocumentSnapshot comentario) {
    Map<String, dynamic> data = comentario.data() as Map<String, dynamic>;
    bool isUser = data['autorTipo'] == 'user';
    bool isOng = data['autorTipo'] == 'ong';
    String autorId = data['autorId'] ?? '';
    String autorNome = data['autorNome'] ?? (isUser ? 'Usuário' : 'ONG');
    String autorTipo = data['autorTipo'] ?? '';

    return GestureDetector(
      onTap: () {
        if (autorId.isNotEmpty && autorTipo.isNotEmpty) {
          _verPerfil(autorId, autorNome, autorTipo);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar do comentarista - CLICÁVEL
                GestureDetector(
                  onTap: () {
                    if (autorId.isNotEmpty && autorTipo.isNotEmpty) {
                      _verPerfil(autorId, autorNome, autorTipo);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUser
                          ? Colors.blue.withOpacity(0.2)
                          : const Color.fromARGB(255, 1, 37, 54)
                              .withOpacity(0.2),
                    ),
                    child: data['autorImagemUrl'] != null &&
                            data['autorImagemUrl'].toString().isNotEmpty
                        ? SmartImage(
                            imageUrl: data['autorImagemUrl'],
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(16),
                            placeholder: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isUser
                                        ? Colors.blue
                                        : const Color.fromARGB(255, 1, 37, 54),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Icon(
                              isUser ? Icons.person : Icons.business,
                              size: 16,
                              color: isUser
                                  ? Colors.blue
                                  : const Color.fromARGB(255, 1, 37, 54),
                            ),
                          )
                        : Icon(
                            isUser ? Icons.person : Icons.business,
                            size: 16,
                            color: isUser
                                ? Colors.blue
                                : const Color.fromARGB(255, 1, 37, 54),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Nome do comentarista - CLICÁVEL
                          GestureDetector(
                            onTap: () {
                              if (autorId.isNotEmpty && autorTipo.isNotEmpty) {
                                _verPerfil(autorId, autorNome, autorTipo);
                              }
                            },
                            child: Text(
                              autorNome,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isUser
                                    ? Colors.blue
                                    : const Color.fromARGB(255, 1, 37, 54),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.blue.withOpacity(0.1)
                                  : const Color.fromARGB(255, 1, 37, 54)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isUser ? 'USUÁRIO' : 'ONG',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUser
                                    ? Colors.blue
                                    : const Color.fromARGB(255, 1, 37, 54),
                              ),
                            ),
                          ),
                          // Indicador visual para todos os comentários (clicáveis)
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      Text(
                        _formatarTempoComentario(data['created_at']),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['texto'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.3,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header do modal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: const Color.fromARGB(255, 1, 37, 54),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      ),
                      Text(
                        'Postagem de ${widget.ongNome}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),

          // Dica para usuários
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toque em um comentário para ver o perfil',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de comentários
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comentarios')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Erro ao carregar comentários',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum comentário ainda',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a comentar!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return _buildComentario(snapshot.data!.docs[index]);
                  },
                );
              },
            ),
          ),

          // Campo de comentário
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 1, 37, 54),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _enviandoComentario
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviandoComentario ? null : _enviarComentario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
