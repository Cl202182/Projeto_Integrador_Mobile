//pg alterada
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  Uint8List? _image;
  final TextEditingController _textController = TextEditingController();
  bool isLoading = false;
  bool isUploadingImage = false;

  // Dados da ONG
  String? nomeOng;
  List<String> areasAtuacao = [];
  bool isLoadingOngData = true;

  // Serviços Firebase
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://portal-ongs.firebasestorage.app' // Mesmo bucket da ONG
      );

  // Controle de upload
  UploadTask? _currentUploadTask;
  StreamSubscription<TaskSnapshot>? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    _carregarDadosOngInicial();
  }

  @override
  void dispose() {
    _cancelCurrentUpload();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosOngInicial() async {
    try {
      Map<String, dynamic>? dadosOng = await _obterDadosOng();
      if (dadosOng != null && mounted) {
        setState(() {
          nomeOng = dadosOng['nome'] ?? 'Minha ONG';
          areasAtuacao = List<String>.from(dadosOng['areasAtuacao'] ?? []);
          isLoadingOngData = false;
        });
      } else {
        setState(() {
          isLoadingOngData = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar dados iniciais da ONG: $e');
      if (mounted) {
        setState(() {
          isLoadingOngData = false;
        });
      }
    }
  }

  void _cancelCurrentUpload() {
    _uploadSubscription?.cancel();
    _currentUploadTask?.cancel();
    _currentUploadTask = null;
    _uploadSubscription = null;
  }

  Future<void> _pickImage() async {
    if (isUploadingImage) {
      _mostrarSnackBar('Aguarde o upload atual terminar', Colors.orange);
      return;
    }

    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);

      if (result != null && result.files.first.bytes != null) {
        final fileSize = result.files.first.bytes!.length;

        // Verificar tamanho máximo (5MB)
        if (fileSize > 5 * 1024 * 1024) {
          _mostrarSnackBar(
              'Imagem muito grande. Máximo 5MB permitido.', Colors.red);
          return;
        }

        setState(() {
          _image = result.files.first.bytes;
        });

        print('Imagem selecionada: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      _mostrarSnackBar('Erro ao selecionar imagem', Colors.red);
    }
  }

  void _clear() {
    _cancelCurrentUpload();
    setState(() {
      _image = null;
      _textController.clear();
    });
  }

  Future<String?> _uploadImagemPostagem() async {
    if (_image == null) return null;

    try {
      print('Iniciando upload da imagem da postagem...');

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Usuário não autenticado');
      }

      _cancelCurrentUpload();

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'post_${uid}_$timestamp.jpg';

      Reference ref = _storage.ref().child('posts/$fileName');

      // Metadados otimizados
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
        customMetadata: {
          'uploadedBy': uid,
          'uploadTime': timestamp,
          'postImage': 'true',
        },
      );

      print('Iniciando upload: $fileName');
      _currentUploadTask = ref.putData(_image!, metadata);

      _uploadSubscription = _currentUploadTask!.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          int progressPercent = (progress * 100).round();
          print('Progresso upload: $progressPercent%');
        },
      );

      TaskSnapshot snapshot = await _currentUploadTask!.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          throw TimeoutException('Upload demorou mais que 10 minutos',
              const Duration(minutes: 10));
        },
      );

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Upload concluído: ${downloadUrl.substring(0, 50)}...');
        return downloadUrl;
      } else {
        throw Exception('Upload falhou com estado: ${snapshot.state}');
      }
    } catch (e) {
      print('Erro no upload da imagem: $e');
      rethrow;
    } finally {
      _currentUploadTask = null;
      _uploadSubscription?.cancel();
      _uploadSubscription = null;
    }
  }

  Future<Map<String, dynamic>?> _obterDadosOng() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erro ao obter dados da ONG: $e');
      return null;
    }
  }

  Future<void> _criarPostagem() async {
    final text = _textController.text.trim();

    // Validações
    if (_image == null || text.isEmpty) {
      _mostrarSnackBar("Selecione uma imagem e escreva algo.", Colors.red);
      return;
    }

    if (text.length > 500) {
      _mostrarSnackBar(
          "O texto deve ter no máximo 500 caracteres.", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Obter dados da ONG
      Map<String, dynamic>? dadosOng = await _obterDadosOng();
      if (dadosOng == null) {
        throw Exception('Dados da ONG não encontrados');
      }

      // 2. Upload da imagem
      setState(() => isUploadingImage = true);
      String? imagemUrl = await _uploadImagemPostagem();
      setState(() => isUploadingImage = false);

      if (imagemUrl == null) {
        throw Exception('Falha no upload da imagem');
      }

      // 3. Criar documento da postagem
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      DocumentReference postRef =
          await FirebaseFirestore.instance.collection('posts').add({
        'ongId': uid,
        'ongNome': dadosOng['nome'] ?? 'ONG Sem Nome',
        'ongImagemUrl': dadosOng['imagemUrl'],
        'texto': text,
        'imagemUrl': imagemUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'likes': 0,
        'comentarios': 0,
        'ativa': true,
        'areasAtuacao': dadosOng['areasAtuacao'] ?? [],
      });

      print('Postagem criada com ID: ${postRef.id}');

      // 4. Atualizar estatísticas da ONG (opcional)
      await FirebaseFirestore.instance.collection('ongs').doc(uid).update({
        'totalPosts': FieldValue.increment(1),
        'lastPostAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        print('Erro ao atualizar estatísticas da ONG: $e');
        // Não falha a operação principal
      });

      // 5. Mostrar sucesso
      _mostrarDialogoSucesso(postRef.id);
    } catch (e) {
      print('Erro ao criar postagem: $e');
      _mostrarSnackBar(
        'Erro ao criar postagem: ${_tratarMensagemErro(e.toString())}',
        Colors.red,
      );
    } finally {
      setState(() {
        isLoading = false;
        isUploadingImage = false;
      });
    }
  }

  String _tratarMensagemErro(String erro) {
    if (erro.contains('TimeoutException') || erro.contains('timeout')) {
      return 'Tempo limite excedido. Verifique sua conexão.';
    } else if (erro.contains('network') || erro.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    } else if (erro.contains('authentication')) {
      return 'Erro de autenticação. Faça login novamente.';
    } else if (erro.contains('permission')) {
      return 'Sem permissão para realizar esta operação.';
    } else if (erro.contains('muito grande')) {
      return 'Imagem muito grande. Escolha uma imagem menor.';
    }
    return erro.length > 100 ? 'Erro ao criar postagem' : erro;
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarDialogoSucesso(String postId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Postagem Publicada!",
                style: TextStyle(
                  color: Color.fromARGB(255, 1, 37, 54),
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Sua postagem foi publicada com sucesso e já está visível para outros usuários."),
            SizedBox(height: 10),
            Text("ID da postagem: ${postId.substring(0, 8)}...",
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo
              Navigator.pop(context); // Volta para tela anterior
            },
            child: Text("Voltar",
                style: TextStyle(
                  color: Color.fromARGB(255, 1, 37, 54),
                  fontWeight: FontWeight.bold,
                )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 1, 37, 54),
            ),
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo
              _clear(); // Limpa o formulário para nova postagem
            },
            child: Text("Nova Postagem", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fundo.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: SizedBox(
                      width: larguraTela * 0.88,
                      height: 150,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    width: larguraTela * 0.88,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'NOVA POSTAGEM',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 1, 37, 54),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Informações da ONG que está postando
                        if (!isLoadingOngData) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 1, 37, 54)
                                  .withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(255, 1, 37, 54)
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 1, 37, 54),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.business,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Postando como',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            nomeOng ?? 'Minha ONG',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 1, 37, 54),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (areasAtuacao.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: areasAtuacao.map((area) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 1, 37, 54),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                area,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (isLoadingOngData)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color.fromARGB(255, 1, 37, 54),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Carregando informações...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Widget de imagem com loading
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                          child: _image != null
                              ? Stack(
                                  key: const ValueKey("image"),
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AspectRatio(
                                        aspectRatio: 4 / 3,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isUploadingImage
                                                  ? Colors.orange
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Stack(
                                              children: [
                                                Image.memory(
                                                  _image!,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                                if (isUploadingImage)
                                                  Container(
                                                    color: Colors.black26,
                                                    child: Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 3,
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            'Enviando...',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isUploadingImage)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _image = null),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : GestureDetector(
                                  key: const ValueKey("button"),
                                  onTap: (isLoading || isUploadingImage)
                                      ? null
                                      : _pickImage,
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: (isLoading || isUploadingImage)
                                          ? Colors.grey
                                          : const Color.fromARGB(
                                              255, 1, 37, 54),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: (isLoading || isUploadingImage)
                                          ? CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            )
                                          : Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 30),

                        // Campo de texto com contador
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              controller: _textController,
                              maxLines: 4,
                              maxLength: 500,
                              enabled: !isLoading && !isUploadingImage,
                              onChanged: (value) =>
                                  setState(() {}), // Para atualizar contador
                              decoration: InputDecoration(
                                hintText:
                                    "Escreva sua mensagem... (máximo 500 caracteres)",
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 1, 37, 54),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: (isLoading || isUploadingImage)
                                    ? Colors.grey[100]
                                    : const Color.fromARGB(255, 240, 240, 240),
                                contentPadding: const EdgeInsets.all(16),
                                counterText: '', // Remove contador padrão
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${_textController.text.length}/500',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textController.text.length > 450
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Botões
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (isLoading || isUploadingImage)
                                    ? null
                                    : _criarPostagem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (isLoading ||
                                          isUploadingImage)
                                      ? Colors.grey
                                      : const Color.fromARGB(255, 1, 37, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: (isLoading || isUploadingImage)
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            isUploadingImage
                                                ? "Enviando..."
                                                : "Publicando...",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      )
                                    : Text("Publicar",
                                        style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (isLoading || isUploadingImage)
                                    ? null
                                    : _clear,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text("Cancelar",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),

                        // Status da operação
                        if (isUploadingImage || isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.orange,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isUploadingImage
                                          ? "Fazendo upload da imagem..."
                                          : "Criando postagem...",
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            child: IconButton(
              onPressed: (isLoading || isUploadingImage)
                  ? null
                  : () {
                      _cancelCurrentUpload();
                      Navigator.pop(context);
                    },
              icon: Icon(Icons.arrow_back,
                  color: (isLoading || isUploadingImage)
                      ? Colors.grey
                      : Colors.white,
                  size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
