//pg alterada
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_application_projeto_integrador/telaChat.dart';
import 'components/bottom_nav_bar.dart';
import 'perfil_user_visualizacao.dart';
import 'image_service.dart';
import 'utils/chat_utils.dart';
import 'comentarios_modal.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  String? nomeUsuario;
  String? userImageUrl;
  bool isLoading = true;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  List<DocumentSnapshot> _posts = [];
  List<DocumentSnapshot> _allPosts = []; // Lista completa sem filtro
  bool _isLoadingPosts = true;
  String? _errorMessage;

  // Filtro de áreas
  List<String> _selectedFilters = [];
  bool _showFilters = false;

  // Áreas disponíveis
  final List<String> areasDisponiveis = [
    'Educação',
    'Saúde',
    'Meio Ambiente',
    'Assistência Social',
    'Cultura',
    'Esporte',
    'Direitos Humanos',
    'Animais',
    'Idosos',
    'Crianças e Adolescentes',
  ];

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _iniciarStreamPosts();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  // Funções de filtro
  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      _aplicarFiltros();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    if (_selectedFilters.isEmpty) {
      _posts = List.from(_allPosts);
    } else {
      _posts = _allPosts.where((post) {
        Map<String, dynamic> data = post.data() as Map<String, dynamic>;
        List<dynamic> areasPost = data['areasAtuacao'] ?? [];

        // Verifica se o post tem pelo menos uma área selecionada
        return _selectedFilters.any((filter) => areasPost.contains(filter));
      }).toList();
    }
  }

  Future<void> _carregarNomeUsuario() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            nomeUsuario = dados['nome'] ?? 'Usuário';
            userImageUrl = dados['imagemUrl'];
            isLoading = false;
          });
        } else {
          setState(() {
            nomeUsuario = 'Usuário';
            userImageUrl = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        nomeUsuario = 'Usuário';
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

      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      print('Usuário autenticado: $currentUserId');

      // Query para obter todos os posts ativos (usuários veem posts de todas as ONGs)
      _postsSubscription = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(20)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          print('Snapshot recebido com ${snapshot.docs.length} documentos');

          // Filtrar posts ativos
          List<DocumentSnapshot> postsAtivos = snapshot.docs.where((doc) {
            Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>? ?? {};

            // Verifica se o post está ativo
            bool isAtivo = data['ativa'] != false;

            return isAtivo;
          }).toList();

          setState(() {
            _allPosts = postsAtivos;
            _aplicarFiltros(); // Aplica filtros se houver
            _isLoadingPosts = false;
            _errorMessage = null;
          });

          print(
              'Posts carregados: ${_allPosts.length}, Após filtro: ${_posts.length}');
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
    Navigator.pushNamed(context, '/perfilUser');
  }

  // Função para navegar para o perfil de uma ONG
  void _verPerfilOng(String ongId, String ongNome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilOngVisualizacaoUser(
          ongId: ongId,
          ongNome: ongNome,
        ),
      ),
    );
  }

  // Função para navegar para perfil a partir dos comentários
  void _verPerfilFromComment(
      String autorId, String autorNome, String autorTipo) {
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

  String _getPrimeiroNome() {
    if (nomeUsuario == null || nomeUsuario!.isEmpty) return 'Usuário';
    return nomeUsuario!.split(' ')[0];
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
            'userId': uid,
            'userType': 'user', // Identificar que é um usuário
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
          // Cabeçalho do post com design moderno - MODIFICADO PARA SER CLICÁVEL
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar com borda elegante - CLICÁVEL
                GestureDetector(
                  onTap: () => _verPerfilOng(
                      data['ongId'] ?? '', data['ongNome'] ?? 'ONG'),
                  child: Container(
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
                    child: Builder(
                      builder: (context) {
                        print('🔥 FEED DEBUG COMPLETO:');
                        print('🔥 TODOS OS CAMPOS: ${data.keys.toList()}');
                        print('🔥 ongId: ${data['ongId']}');
                        print('🔥 autorId: ${data['autorId']}');
                        print('🔥 autorImagemUrl: ${data['autorImagemUrl']}');
                        print('🔥 ongImagemUrl: ${data['ongImagemUrl']}');
                        print('🔥 imagemUrl: ${data['imagemUrl']}');

                        // Tentar todas as possibilidades de URL de imagem
                        String? imageUrl;

                        if (data['autorImagemUrl'] != null &&
                            data['autorImagemUrl'].toString().isNotEmpty) {
                          imageUrl = data['autorImagemUrl'];
                          print('🔥 Avatar feed - usando autorImagemUrl');
                        } else if (data['ongImagemUrl'] != null &&
                            data['ongImagemUrl'].toString().isNotEmpty) {
                          imageUrl = data['ongImagemUrl'];
                          print('🔥 Avatar feed - usando ongImagemUrl');
                        } else if (data['imagemUrl'] != null &&
                            data['imagemUrl'].toString().isNotEmpty) {
                          imageUrl = data['imagemUrl'];
                          print('🔥 Avatar feed - usando imagemUrl');
                        }

                        if (imageUrl != null) {
                          print('🔥 Avatar feed - URL final: $imageUrl');
                          return CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.transparent,
                            child: ClipOval(
                              child: SmartImage(
                                imageUrl: imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color.fromARGB(255, 1, 37, 54),
                                  child: const Icon(
                                    Icons.business,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        print(
                            '🔥 Avatar feed - nenhuma URL encontrada, usando fallback');
                        return CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info da ONG - CLICÁVEL
                Expanded(
                  child: GestureDetector(
                    onTap: () => _verPerfilOng(
                        data['ongId'] ?? '', data['ongNome'] ?? 'ONG'),
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
                            const SizedBox(width: 8),
                            Text(
                              '• Toque para ver perfil',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

                    // Botão Comentar moderno - FUNCIONAL
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(post.id)
                            .collection('comentarios')
                            .snapshots(),
                        builder: (context, comentariosSnapshot) {
                          int totalComentarios = comentariosSnapshot.hasData
                              ? comentariosSnapshot.data!.docs.length
                              : 0;

                          return InkWell(
                            onTap: () => _mostrarComentarios(
                                post.id, data['ongNome'] ?? 'ONG'),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                    color: Colors.grey[200]!, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.comment_outlined,
                                      color: Colors.grey[600], size: 20),
                                  if (totalComentarios > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '$totalComentarios',
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
                          );
                        },
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
                'Aguarde as ONGs compartilharem conteúdo!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo/Ícone do Portal
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Texto PORTAL
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PORTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 2,
        actions: [
          // Botão de filtro
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                if (_selectedFilters.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${_selectedFilters.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Painel de filtros
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 120 : 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtrar por área de interesse:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedFilters.isNotEmpty)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text(
                              'Limpar',
                              style: TextStyle(
                                color: Color.fromARGB(255, 1, 37, 54),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: areasDisponiveis.map((area) {
                          bool isSelected = _selectedFilters.contains(area);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                area,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color.fromARGB(255, 1, 37, 54),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) => _toggleFilter(area),
                              backgroundColor: Colors.grey[200],
                              selectedColor:
                                  const Color.fromARGB(255, 1, 37, 54),
                              checkmarkColor: Colors.white,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feed de postagens
          Expanded(
            child: Container(
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
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        isOng: false,
        profileImageUrl: userImageUrl,
      ),
    );
  }
}

// Modal para comentários
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

  // Função para navegar para perfil a partir dos comentários
  void _verPerfilFromComment(
      String autorId, String autorNome, String autorTipo) {
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

  // Função para proxy de imagens
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

  Future<void> _enviarComentario() async {
    if (_comentarioController.text.trim().isEmpty) return;

    setState(() {
      _enviandoComentario = true;
    });

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Buscar dados do usuário
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String userName = 'Usuário';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['nome'] ?? 'Usuário';
      }

      // Adicionar comentário
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comentarios')
          .add({
        'texto': _comentarioController.text.trim(),
        'autorId': uid,
        'autorNome': userName,
        'autorTipo': 'user',
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

  Widget _buildComentario(DocumentSnapshot comentario) {
    Map<String, dynamic> data = comentario.data() as Map<String, dynamic>;
    bool isUser = data['autorTipo'] == 'user';
    String autorId = data['autorId'] ?? '';
    String autorNome = data['autorNome'] ?? (isUser ? 'Usuário' : 'ONG');
    String autorTipo = data['autorTipo'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar com imagem de perfil - CLICÁVEL
              GestureDetector(
                onTap: () {
                  if (autorId.isNotEmpty && autorTipo.isNotEmpty) {
                    _verPerfilFromComment(autorId, autorNome, autorTipo);
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUser
                        ? Colors.blue.withOpacity(0.2)
                        : const Color.fromARGB(255, 1, 37, 54).withOpacity(0.2),
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
                              color: isUser
                                  ? Colors.blue.withOpacity(0.2)
                                  : const Color.fromARGB(255, 1, 37, 54)
                                      .withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUser ? Icons.person : Icons.business,
                              size: 16,
                              color: isUser
                                  ? Colors.blue
                                  : const Color.fromARGB(255, 1, 37, 54),
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
                    // Nome clicável
                    GestureDetector(
                      onTap: () {
                        if (autorId.isNotEmpty && autorTipo.isNotEmpty) {
                          _verPerfilFromComment(autorId, autorNome, autorTipo);
                        }
                      },
                      child: Text(
                        data['autorNome'] ?? (isUser ? 'Usuário' : 'ONG'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isUser
                              ? Colors.blue
                              : const Color.fromARGB(255, 1, 37, 54),
                        ),
                      ),
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
            ),
          ),
        ],
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
                Text(
                  'Comentários',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[600],
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

// Classe para visualização do perfil de ONGs (para usuários)
class PerfilOngVisualizacaoUser extends StatefulWidget {
  final String ongId;
  final String ongNome;

  const PerfilOngVisualizacaoUser({
    super.key,
    required this.ongId,
    required this.ongNome,
  });

  @override
  State<PerfilOngVisualizacaoUser> createState() =>
      _PerfilOngVisualizacaoUserState();
}

class _PerfilOngVisualizacaoUserState extends State<PerfilOngVisualizacaoUser> {
  Map<String, dynamic>? ongData;
  bool isLoading = true;
  List<DocumentSnapshot> postagens = [];
  bool isLoadingPosts = true;
  String? userImageUrl;
  String userType = 'ong'; // Tipo padrão para esta tela

  @override
  void initState() {
    super.initState();
    _carregarDadosOng();
    _carregarPostagens();
  }

  Future<void> _carregarDadosOng() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('ongs')
          .doc(widget.ongId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          ongData = data;
          userImageUrl = data['imagemUrl']; // Carregar imagem da ONG
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

  Future<void> _carregarPostagens() async {
    try {
      // Primeira tentativa: sem orderBy para evitar problemas de índice
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('ongId', isEqualTo: widget.ongId)
          .where('ativa', isEqualTo: true)
          .limit(10)
          .get();

      // Se não encontrou postagens, tenta sem o filtro 'ativa'
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('ongId', isEqualTo: widget.ongId)
            .limit(10)
            .get();
      }

      setState(() {
        postagens = snapshot.docs;
        isLoadingPosts = false;
      });
    } catch (e) {
      print('Erro ao carregar postagens: $e');
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  // Função para iniciar chat com a ONG
  Future<void> _iniciarChat() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Buscar dados do usuário atual
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      String currentUserNome = 'Usuário';
      if (currentUserDoc.exists) {
        Map<String, dynamic> currentData =
            currentUserDoc.data() as Map<String, dynamic>;
        currentUserNome = currentData['nome'] ?? 'Usuário';
      }

      // Criar ou buscar chatId existente usando função padronizada
      String chatId = ChatUtils.generateChatId(currentUserId, widget.ongId);

      // Verificar se o chat já existe no Firebase Realtime Database
      DatabaseReference chatRef =
          FirebaseDatabase.instance.ref().child('chats/$chatId');
      DatabaseEvent snapshot = await chatRef.once();

      if (!snapshot.snapshot.exists) {
        // Criar novo chat
        await chatRef.set({
          'participants': [currentUserId, widget.ongId],
          'createdAt': ServerValue.timestamp,
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
        });
      }

      // Navegar para a tela de chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaChat(),
          settings: RouteSettings(
            arguments: {
              'chatId': chatId,
              'userName': widget.ongNome,
              'userId': widget.ongId,
              'userType': 'ong',
            },
          ),
        ),
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

  // Função para proxy de imagens
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
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
        child: (ongData?['imagemUrl'] != null &&
                ongData!['imagemUrl'].toString().isNotEmpty)
            ? Image.network(
                _getProxiedImageUrl(ongData!['imagemUrl']),
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
                    Icons.business,
                    size: 40,
                    color: Color.fromARGB(255, 1, 37, 54),
                  );
                },
              )
            : const Icon(
                Icons.business,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPostagem(DocumentSnapshot post) {
    Map<String, dynamic> data = post.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: () async {
        // Abrir modal de comentários
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ComentariosModal(
            postId: post.id,
            ongNome: widget.ongNome,
          ),
        );
        // Recarregar postagens quando o modal for fechado
        _carregarPostagens();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem da postagem
            if (data['imagemUrl'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  _getProxiedImageUrl(data['imagemUrl']),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    );
                  },
                ),
              ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto
                  Text(
                    data['texto'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Dica visual de que é clicável
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Toque para ver mais e comentar',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botões de ação
                  Row(
                    children: [
                      // Botão de Like
                      GestureDetector(
                        onTap: () {
                          _toggleLike(post.id, data);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: (data['likedBy'] ?? []).contains(
                                    FirebaseAuth.instance.currentUser?.uid)
                                ? Colors.red.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (data['likedBy'] ?? []).contains(
                                        FirebaseAuth.instance.currentUser?.uid)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: (data['likedBy'] ?? []).contains(
                                        FirebaseAuth.instance.currentUser?.uid)
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${data['likes'] ?? 0}',
                                style: TextStyle(
                                  color: (data['likedBy'] ?? []).contains(
                                          FirebaseAuth
                                              .instance.currentUser?.uid)
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botão de Comentários
                      GestureDetector(
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ComentariosModal(
                              postId: post.id,
                              ongNome: widget.ongNome,
                            ),
                          );
                          // Recarregar postagens quando o modal for fechado
                          _carregarPostagens();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: 18, color: Colors.blue[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${data['comentarios'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para dar like na postagem
  Future<void> _toggleLike(String postId, Map<String, dynamic> postData) async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);

      // Verificar se o usuário já deu like
      List<dynamic> likes = postData['likedBy'] ?? [];
      bool jaLikado = likes.contains(currentUserId);

      if (jaLikado) {
        // Remover like
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Adicionar like - garantir que os campos existam
        Map<String, dynamic> updateData = {
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        };

        // Se o campo likes não existir, criar com valor 1, senão incrementar
        if (postData['likes'] == null) {
          updateData['likes'] = 1;
        } else {
          updateData['likes'] = FieldValue.increment(1);
        }

        await postRef.update(updateData);
      }

      // Recarregar postagens para atualizar UI
      _carregarPostagens();
    } catch (e) {
      print('Erro ao dar like: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.ongNome,
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
                            _buildImagemPerfil(),
                            const SizedBox(height: 16),
                            Text(
                              widget.ongNome,
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

                      // Botão de Chat em destaque
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton.icon(
                          onPressed: _iniciarChat,
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'Iniciar Conversa',
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

                      // Informações da ONG
                      _buildInfoCard(
                        'Descrição',
                        ongData?['descricao'],
                        Icons.description,
                      ),

                      _buildInfoCard(
                        'Telefone',
                        ongData?['telefone'],
                        Icons.phone,
                      ),

                      _buildInfoCard(
                        'WhatsApp',
                        ongData?['whatsapp'],
                        Icons.chat,
                      ),

                      _buildInfoCard(
                        'Endereço',
                        ongData?['endereco'],
                        Icons.location_on,
                      ),

                      _buildInfoCard(
                        'Site',
                        ongData?['site'],
                        Icons.web,
                      ),

                      _buildInfoCard(
                        'Instagram',
                        ongData?['instagram'] != null
                            ? '@${ongData!['instagram'].replaceAll('@', '')}'
                            : null,
                        Icons.camera_alt,
                      ),

                      _buildInfoCard(
                        'Facebook',
                        ongData?['facebook'],
                        Icons.facebook,
                      ),

                      // Áreas de atuação
                      _buildAreasAtuacao(),

                      // Seção de Postagens
                      const SizedBox(height: 20),
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 1, 37, 54)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.article,
                                    color: Color.fromARGB(255, 1, 37, 54),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Postagens Públicas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 1, 37, 54),
                                    ),
                                  ),
                                ),
                                if (!isLoadingPosts && postagens.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color.fromARGB(255, 1, 37, 54),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${postagens.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Lista de postagens
                            if (isLoadingPosts)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color.fromARGB(255, 1, 37, 54),
                                  ),
                                ),
                              )
                            else if (postagens.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Nenhuma postagem pública ainda',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: postagens
                                    .map((post) => _buildPostagem(post))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
