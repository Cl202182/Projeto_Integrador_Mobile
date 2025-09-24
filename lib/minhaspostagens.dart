import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'comentarios_modal.dart';
import 'image_service.dart';

class MinhasPostagensOng extends StatefulWidget {
  const MinhasPostagensOng({super.key});

  @override
  State<MinhasPostagensOng> createState() => _MinhasPostagensOngState();
}

class _MinhasPostagensOngState extends State<MinhasPostagensOng> {
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  List<DocumentSnapshot> _minhasPosts = [];
  bool _isLoadingPosts = true;
  String? _errorMessage;
  String? nomeOng;

  @override
  void initState() {
    super.initState();
    // Limpa cache de imagens ao inicializar (útil após login/logout)
    ImageService().clearCache();
    _carregarNomeOng();
    _iniciarStreamMinhasPosts();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _carregarNomeOng() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            nomeOng = dados['nome'] ?? 'ONG';
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar nome da ONG: $e');
    }
  }

  void _iniciarStreamMinhasPosts() {
    print('Iniciando stream de minhas postagens...');

    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        print('Usuário não autenticado');
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoadingPosts = false;
        });
        return;
      }

      print('Usuário autenticado: $currentUserId');

      // Primeiro, tentar sem orderBy para evitar problemas de índice
      _postsSubscription = FirebaseFirestore.instance
          .collection('posts')
          .where('ongId', isEqualTo: currentUserId)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          print('Snapshot recebido com ${snapshot.docs.length} documentos');

          // Ordenar manualmente no cliente
          List<DocumentSnapshot> sortedDocs = snapshot.docs.toList();
          sortedDocs.sort((a, b) {
            Timestamp? aTime = a.data() != null
                ? (a.data() as Map<String, dynamic>)['created_at']
                : null;
            Timestamp? bTime = b.data() != null
                ? (b.data() as Map<String, dynamic>)['created_at']
                : null;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime
                .compareTo(aTime); // Ordem decrescente (mais recente primeiro)
          });

          setState(() {
            _minhasPosts = sortedDocs;
            _isLoadingPosts = false;
            _errorMessage = null;
          });

          print('Posts carregados com sucesso: ${_minhasPosts.length}');
        },
        onError: (error) {
          print('Erro detalhado no stream: $error');
          print('Tipo do erro: ${error.runtimeType}');

          String mensagemErro = 'Erro desconhecido';
          if (error.toString().contains('permission-denied')) {
            mensagemErro = 'Sem permissão para acessar suas postagens';
          } else if (error.toString().contains('failed-precondition')) {
            mensagemErro = 'Índice do banco de dados necessário';
          } else if (error.toString().contains('unavailable')) {
            mensagemErro = 'Serviço temporariamente indisponível';
          } else {
            mensagemErro = 'Erro de conexão com o servidor';
          }

          setState(() {
            _errorMessage = mensagemErro;
            _isLoadingPosts = false;
          });
        },
      );
    } catch (e) {
      print('Erro ao inicializar stream: $e');
      setState(() {
        _errorMessage = 'Erro ao conectar: ${e.toString()}';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _testarConexaoFirestore() async {
    try {
      print('Testando conexão com Firestore...');

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('Usuário não autenticado para teste');
        return;
      }

      // Teste simples de conexão
      QuerySnapshot testSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('ongId', isEqualTo: uid)
          .limit(1)
          .get()
          .timeout(Duration(seconds: 10));

      print(
          'Teste de conexão bem-sucedido. Documentos encontrados: ${testSnapshot.docs.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conexão OK. Documentos: ${testSnapshot.docs.length}'),
          backgroundColor: Colors.green,
        ),
      );

      // Se o teste passou, tentar novamente o stream
      setState(() {
        _isLoadingPosts = true;
        _errorMessage = null;
      });
      _postsSubscription?.cancel();
      _iniciarStreamMinhasPosts();
    } catch (e) {
      print('Erro no teste de conexão: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Função para mostrar comentários
  void _mostrarComentarios(String postId, String ongNome) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComentariosModal(
        postId: postId,
        ongNome: ongNome,
      ),
    );
  }

  // SOLUÇÃO SIMPLES: PROXY PARA IMAGENS
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  String _formatarTempo(Timestamp? timestamp) {
    if (timestamp == null) return 'Agora';

    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${postTime.day}/${postTime.month}/${postTime.year}';
    }
  }

  Future<void> _alternarStatusPost(String postId, bool ativoAtual) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'ativa': !ativoAtual});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ativoAtual ? 'Post desativado' : 'Post ativado'),
          backgroundColor: ativoAtual ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao alterar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _excluirPost(String postId) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Postagem'),
          content: const Text(
              'Tem certeza que deseja excluir esta postagem? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Postagem excluída com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir postagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMeuPost(DocumentSnapshot post) {
    Map<String, dynamic> data = post.data() as Map<String, dynamic>;
    bool isAtivo = data['ativa'] != false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAtivo ? null : Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do post
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar da ONG
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 1, 37, 54),
                        const Color.fromARGB(255, 1, 37, 54).withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 1, 37, 54)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: data['ongImagemUrl'] != null &&
                            data['ongImagemUrl'].toString().isNotEmpty
                        ? SmartImage(
                            imageUrl: data['ongImagemUrl'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(24),
                            placeholder: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Icon(Icons.business,
                                color: Colors.white, size: 24),
                          )
                        : Icon(Icons.business, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Info da postagem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nomeOng ?? 'Minha ONG',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromARGB(255, 1, 37, 54),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAtivo ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAtivo ? 'ATIVO' : 'INATIVO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _formatarTempo(data['created_at']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu de opções
                PopupMenuButton(
                  icon:
                      Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isAtivo ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: isAtivo ? Colors.orange : Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            isAtivo ? 'Desativar' : 'Ativar',
                            style: TextStyle(
                              color: isAtivo ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red[400]),
                          SizedBox(width: 8),
                          Text('Excluir',
                              style: TextStyle(color: Colors.red[400])),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'toggle') {
                      _alternarStatusPost(post.id, isAtivo);
                    } else if (value == 'delete') {
                      _excluirPost(post.id);
                    }
                  },
                ),
              ],
            ),
          ),

          // Texto da postagem
          if (data['texto'] != null && data['texto'].toString().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                data['texto'],
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.2,
                ),
              ),
            ),

          // Imagem da postagem
          if (data['imagemUrl'] != null &&
              data['imagemUrl'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SmartImage(
                    imageUrl: data['imagemUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    placeholder: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: CircularProgressIndicator(
                                color: const Color.fromARGB(255, 1, 37, 54),
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Carregando imagem...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[200]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.broken_image,
                                  size: 32, color: Colors.grey[400]),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tags das áreas de atuação
          if (data['areasAtuacao'] != null &&
              (data['areasAtuacao'] as List).isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['areasAtuacao'] as List)
                    .take(3)
                    .map((area) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 1, 37, 54)
                                    .withOpacity(0.1),
                                const Color.fromARGB(255, 1, 37, 54)
                                    .withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color.fromARGB(255, 1, 37, 54)
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            area.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 1, 37, 54),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

          // Divider sutil
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[200]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Estatísticas do post
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(post.id)
                .collection('likes')
                .snapshots(),
            builder: (context, likesSnapshot) {
              int likes =
                  likesSnapshot.hasData ? likesSnapshot.data!.docs.length : 0;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id)
                    .collection('comentarios')
                    .snapshots(),
                builder: (context, comentariosSnapshot) {
                  int comentarios = comentariosSnapshot.hasData
                      ? comentariosSnapshot.data!.docs.length
                      : 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Estatística de likes
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite, color: Colors.red, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '$likes curtidas',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Estatística de comentários - CLICÁVEL
                        InkWell(
                          onTap: () => _mostrarComentarios(
                              post.id, nomeOng ?? 'Minha ONG'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment,
                                    color: Colors.blue, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '$comentarios comentários',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.touch_app,
                                    color: Colors.blue, size: 12),
                              ],
                            ),
                          ),
                        ),

                        // Status visual
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAtivo
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAtivo
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAtivo
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isAtivo ? Colors.green : Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                isAtivo ? 'Visível' : 'Oculto',
                                style: TextStyle(
                                  color: isAtivo ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMinhasPostagensContent() {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 1, 37, 54),
              ),
              SizedBox(height: 16),
              Text(
                'Carregando suas postagens...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingPosts = true;
                        _errorMessage = null;
                      });
                      _iniciarStreamMinhasPosts();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                    ),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _testarConexaoFirestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Testar Conexão',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_minhasPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.post_add_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Você ainda não tem postagens',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie sua primeira postagem para começar a compartilhar!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/postagem');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Criar Primeira Postagem',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color.fromARGB(255, 1, 37, 54),
      onRefresh: () async {
        setState(() {
          _isLoadingPosts = true;
        });
        _postsSubscription?.cancel();
        _iniciarStreamMinhasPosts();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _minhasPosts.length,
        itemBuilder: (context, index) {
          return _buildMeuPost(_minhasPosts[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.my_library_books,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Minhas Postagens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_minhasPosts.length} ${_minhasPosts.length == 1 ? 'postagem' : 'postagens'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova Postagem',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/postagem');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: _buildMinhasPostagensContent(),
      ),
    );
  }
}
