import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class HomeONG extends StatefulWidget {
  const HomeONG({super.key});

  @override
  State<HomeONG> createState() => _HomeONGState();
}

class _HomeONGState extends State<HomeONG> {
  String? nomeOng;
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  List<DocumentSnapshot> _posts = [];
  bool _isLoadingPosts = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarNomeOng();
    _iniciarStreamPosts();
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
            isLoading = false;
          });
        } else {
          setState(() {
            nomeOng = 'ONG';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        nomeOng = 'ONG';
        isLoading = false;
      });
    }
  }

  Future<void> _testarConexaoFirestore() async {
    try {
      print('Testando conexão com Firestore...');

      // Teste simples de conexão
      QuerySnapshot testSnapshot = await FirebaseFirestore.instance
          .collection('posts')
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
      _iniciarStreamPosts();
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

  void _iniciarStreamPosts() {
    print('Iniciando stream de posts...');

    try {
      // Verificar se o usuário está autenticado
      if (FirebaseAuth.instance.currentUser == null) {
        print('Usuário não autenticado');
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoadingPosts = false;
        });
        return;
      }

      print('Usuário autenticado: ${FirebaseAuth.instance.currentUser!.uid}');

      // Query mais simples para evitar problemas de índice
      _postsSubscription = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(20) // Reduzir limite inicial
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          print('Snapshot recebido com ${snapshot.docs.length} documentos');

          // Filtrar posts ativos no lado do cliente se necessário
          List<DocumentSnapshot> postsAtivos = snapshot.docs.where((doc) {
            Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>? ?? {};
            return data['ativa'] != false; // Considera true se campo não existe
          }).toList();

          setState(() {
            _posts = postsAtivos;
            _isLoadingPosts = false;
            _errorMessage = null;
          });

          print('Posts filtrados e carregados: ${_posts.length}');
        },
        onError: (error) {
          print('Erro detalhado no stream: $error');
          print('Tipo do erro: ${error.runtimeType}');

          String mensagemErro = 'Erro desconhecido';
          if (error.toString().contains('permission-denied')) {
            mensagemErro = 'Sem permissão para acessar postagens';
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

  void _visualizarPerfil() {
    Navigator.pushNamed(context, '/visong');
  }

  // SOLUÇÃO DEFINITIVA: PROXY PARA IMAGENS
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

  Future<void> _darLike(String postId, bool jaGostou, int likesAtuais) async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      DocumentReference likeRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(uid);

      if (jaGostou) {
        // Remover like
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.delete(likeRef);
          transaction.update(postRef, {'likes': likesAtuais - 1});
        });
      } else {
        // Adicionar like
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(likeRef, {
            'ongId': uid,
            'created_at': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {'likes': likesAtuais + 1});
        });
      }
    } catch (e) {
      print('Erro ao dar like: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao curtir postagem'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPost(DocumentSnapshot post) {
    Map<String, dynamic> data = post.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Cabeçalho do post com design moderno
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar com borda elegante
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
                        ? ClipOval(
                            child: Image.network(
                              _getProxiedImageUrl(data['ongImagemUrl']),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.business,
                                    color: Colors.white, size: 24);
                              },
                            ),
                          )
                        : Icon(Icons.business, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Info da ONG
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['ongNome'] ?? 'ONG',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color.fromARGB(255, 1, 37, 54),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
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
                // Menu mais elegante
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_horiz,
                        color: Colors.grey[600], size: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.report_outlined,
                                size: 18, color: Colors.red[400]),
                            SizedBox(width: 8),
                            Text('Reportar',
                                style: TextStyle(color: Colors.red[400])),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'report') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Postagem reportada'),
                            backgroundColor: Colors.red[400],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Texto da postagem com melhor tipografia
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

          // Imagem da postagem com bordas arredondadas
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
                  child: Image.network(
                    _getProxiedImageUrl(data['imagemUrl']),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[50]!],
                          ),
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
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
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
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.grey[200]!],
                          ),
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
                      );
                    },
                  ),
                ),
              ),
            ),

          // Tags das áreas de atuação com design moderno
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

          // Ações do post com design moderno
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(post.id)
                .collection('likes')
                .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                .snapshots(),
            builder: (context, likeSnapshot) {
              bool jaGostou = likeSnapshot.hasData && likeSnapshot.data!.exists;
              int likes = data['likes'] ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Botão Like moderno
                    Expanded(
                      child: InkWell(
                        onTap: () => _darLike(post.id, jaGostou, likes),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: jaGostou
                                ? Colors.red.withOpacity(0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: jaGostou
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  jaGostou
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      jaGostou ? Colors.red : Colors.grey[600],
                                  size: 20,
                                  key: ValueKey(jaGostou),
                                ),
                              ),
                              if (likes > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '$likes',
                                  style: TextStyle(
                                    color: jaGostou
                                        ? Colors.red
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Botão Comentar moderno
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Comentários em breve!'),
                              backgroundColor:
                                  const Color.fromARGB(255, 1, 37, 54),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(25),
                            border:
                                Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.comment_outlined,
                                  color: Colors.grey[600], size: 20),
                              if (data['comentarios'] != null &&
                                  data['comentarios'] > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '${data['comentarios']}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Botão Compartilhar moderno
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Compartilhamento em breve!'),
                              backgroundColor:
                                  const Color.fromARGB(255, 1, 37, 54),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(25),
                            border:
                                Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: Icon(Icons.share_outlined,
                              color: Colors.grey[600], size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
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
                'Carregando postagens...',
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
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingPosts = true;
                    _errorMessage = null;
                  });
                  _iniciarStreamPosts();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                ),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
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
                'Nenhuma postagem encontrada',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Seja a primeira ONG a compartilhar algo!',
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
                  'Criar Postagem',
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
        _iniciarStreamPosts();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return _buildPost(_posts[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _visualizarPerfil,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.business,
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
                      'Bem-vindo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      isLoading ? 'Carregando...' : (nomeOng ?? 'ONG'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add),
            tooltip: 'Criar Postagem',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/postagem');
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Chat',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/contatoOng');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Ver Perfil',
            color: Colors.white,
            onPressed: _visualizarPerfil,
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
        child: _buildFeedContent(),
      ),
    );
  }
}
