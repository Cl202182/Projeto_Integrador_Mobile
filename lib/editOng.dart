import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class PerfilOng extends StatefulWidget {
  const PerfilOng({super.key});

  @override
  State<PerfilOng> createState() => _PerfilOngState();
}

class _PerfilOngState extends State<PerfilOng> {
  GlobalKey<FormState> perfilKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController nomeController = TextEditingController();
  TextEditingController descricaoController = TextEditingController();
  TextEditingController telefoneController = TextEditingController();
  TextEditingController whatsappController = TextEditingController();
  TextEditingController enderecoController = TextEditingController();
  TextEditingController siteController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController facebookController = TextEditingController();

  // Estado
  String? imagemUrl;
  String? imagemUrlOriginal;
  bool isLoading = false;
  bool isUploadingImage = false;
  bool imagemFoiAlterada = false;
  bool isInitializing = true;

  List<String> areasAtuacao = [];
  Map<String, String> horarioFuncionamento = {
    'segunda': '',
    'terca': '',
    'quarta': '',
    'quinta': '',
    'sexta': '',
    'sabado': '',
    'domingo': '',
  };

  // Serviços
  final ImagePicker _picker = ImagePicker();
  // CONFIGURAÇÃO OTIMIZADA - BUCKET BRASIL (REGIÃO SA)
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://portal-ongs.firebasestorage.app' // Bucket regional SA
      );

  // Controle de upload
  UploadTask? _currentUploadTask;
  StreamSubscription<TaskSnapshot>? _uploadSubscription;

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

  // SOLUÇÃO DEFINITIVA: PROXY PARA IMAGENS
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Para web, usar proxy CORS que resolve o problema
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl; // Mobile usa URL original
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _cancelCurrentUpload();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    nomeController.dispose();
    descricaoController.dispose();
    telefoneController.dispose();
    whatsappController.dispose();
    enderecoController.dispose();
    siteController.dispose();
    instagramController.dispose();
    facebookController.dispose();
  }

  void _cancelCurrentUpload() {
    _uploadSubscription?.cancel();
    _currentUploadTask?.cancel();
    _currentUploadTask = null;
    _uploadSubscription = null;
  }

  Future<void> _initializeServices() async {
    try {
      setState(() => isInitializing = true);
      await carregarDadosPerfil();
    } catch (e) {
      print('Erro na inicialização: $e');
    } finally {
      if (mounted) {
        setState(() => isInitializing = false);
      }
    }
  }

  Future<void> carregarDadosPerfil() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              nomeController.text = dados['nome'] ?? '';
              descricaoController.text = dados['descricao'] ?? '';
              telefoneController.text = dados['telefone'] ?? '';
              whatsappController.text = dados['whatsapp'] ?? '';
              enderecoController.text = dados['endereco'] ?? '';
              siteController.text = dados['site'] ?? '';
              instagramController.text = dados['instagram'] ?? '';
              facebookController.text = dados['facebook'] ?? '';
              imagemUrlOriginal = dados['imagemUrl'];
              imagemUrl = dados['imagemUrl'];
              areasAtuacao = List<String>.from(dados['areasAtuacao'] ?? []);
              if (dados['horarioFuncionamento'] != null) {
                horarioFuncionamento =
                    Map<String, String>.from(dados['horarioFuncionamento']);
              }
            });
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
    }
  }

  Future<bool> _solicitarPermissoes() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        Map<Permission, PermissionStatus> permissions = await [
          Permission.camera,
          Permission.storage,
          Permission.photos,
        ].request();
        return permissions.values
            .any((status) => status == PermissionStatus.granted);
      } else if (Platform.isIOS) {
        Map<Permission, PermissionStatus> permissions = await [
          Permission.camera,
          Permission.photos,
        ].request();
        return permissions.values
            .any((status) => status == PermissionStatus.granted);
      }
      return true;
    } catch (e) {
      print('Erro ao solicitar permissões: $e');
      return true;
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      print('📱 Selecionando imagem da fonte: $source');
      _cancelCurrentUpload();

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('📸 Imagem selecionada: ${image.name}');

        final fileSize = await image.length();
        print(
            '📊 Tamanho do arquivo: ${(fileSize / 1024).toStringAsFixed(2)} KB');

        if (fileSize > 5 * 1024 * 1024) {
          print('❌ Imagem muito grande');
          return;
        }

        final bytes = await image.readAsBytes();
        await _processarImagemComDiagnostico(bytes);
      } else {
        print('❌ Nenhuma imagem selecionada');
      }
    } catch (e) {
      print('💥 Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _processarImagemComDiagnostico(Uint8List imageBytes) async {
    if (!mounted) return;

    setState(() => isUploadingImage = true);

    try {
      print('🎯 Iniciando processamento da imagem...');

      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Usuário não autenticado');
      }

      String? novaImagemUrl = await _uploadComDiagnostico(
        imageBytes: imageBytes,
        uid: uid,
      ).timeout(
        const Duration(minutes: 15),
        onTimeout: () {
          throw TimeoutException('Upload demorou muito para completar',
              const Duration(minutes: 15));
        },
      );

      if (novaImagemUrl != null && novaImagemUrl.isNotEmpty) {
        if (mounted) {
          setState(() {
            imagemUrl = novaImagemUrl;
            imagemFoiAlterada = true;
          });

          print('🎉 Imagem processada com sucesso!');
        }
      } else {
        throw Exception('URL da imagem está vazia');
      }
    } catch (e) {
      print('💥 Erro no processamento: $e');
    } finally {
      if (mounted) {
        setState(() => isUploadingImage = false);
      }
    }
  }

  Future<String?> _uploadComDiagnostico({
    required Uint8List imageBytes,
    required String uid,
  }) async {
    try {
      print('🚀 Iniciando upload com diagnóstico...');
      print('📊 Tamanho da imagem: ${imageBytes.length} bytes');

      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception(
            'Imagem muito grande: ${(imageBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      _cancelCurrentUpload();

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'perfil_${uid}_$timestamp.jpg';

      print('📁 Nome do arquivo: $fileName');

      Reference ref = _storage.ref().child('ongs/perfil/$fileName');
      print('📍 Caminho: ${ref.fullPath}');

      // METADADOS OTIMIZADOS PARA WEB/CHROME
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Cache por 1 ano
        customMetadata: {
          'uploadedBy': uid,
          'uploadTime': timestamp,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, X-Requested-With, Content-Type, Accept, Authorization',
        },
      );

      print('🔄 Iniciando upload...');
      _currentUploadTask = ref.putData(imageBytes, metadata);

      _uploadSubscription = _currentUploadTask!.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          int progressPercent = (progress * 100).round();

          print(
              '📈 Progresso: $progressPercent% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
        },
        onError: (error) {
          print('❌ Erro no stream: $error');
        },
      );

      print('⏳ Aguardando conclusão do upload...');
      TaskSnapshot snapshot = await _currentUploadTask!.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          print('⏰ Timeout após 10 minutos');
          throw TimeoutException('Upload demorou mais que 10 minutos',
              const Duration(minutes: 10));
        },
      );

      print('📋 Estado final: ${snapshot.state}');
      print('📊 Bytes transferidos: ${snapshot.bytesTransferred}');

      if (snapshot.state == TaskState.success) {
        print('🎉 Upload concluído com sucesso!');

        print('🔗 Obtendo URL de download...');
        String downloadUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw TimeoutException(
                'Timeout ao obter URL', const Duration(minutes: 2));
          },
        );

        print('✅ URL obtida: ${downloadUrl.substring(0, 100)}...');
        return downloadUrl;
      } else {
        throw Exception('Upload falhou com estado: ${snapshot.state}');
      }
    } catch (e) {
      print('💥 Erro detalhado no upload: $e');
      print('📍 Tipo do erro: ${e.runtimeType}');

      if (e is FirebaseException) {
        print('🔥 Código do erro Firebase: ${e.code}');
        print('🔥 Mensagem do erro Firebase: ${e.message}');
      }

      rethrow;
    } finally {
      print('🧹 Limpando recursos...');
      _currentUploadTask = null;
      _uploadSubscription?.cancel();
      _uploadSubscription = null;
    }
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

  Future<void> selecionarImagem() async {
    if (isUploadingImage) {
      _mostrarSnackBar('Aguarde o upload atual terminar', Colors.orange);
      return;
    }

    final hasPermission = await _solicitarPermissoes();
    if (!hasPermission) {
      _mostrarSnackBar('Permissões necessárias não concedidas', Colors.red);
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Foto de Perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
                const SizedBox(height: 20),
                if (!kIsWeb) ...[
                  _buildOpcaoImagem(
                    icone: Icons.camera_alt,
                    titulo: 'Tirar Foto',
                    subtitulo: 'Usar câmera do dispositivo',
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarImagem(ImageSource.camera);
                    },
                  ),
                ],
                _buildOpcaoImagem(
                  icone: Icons.photo_library,
                  titulo: kIsWeb ? 'Escolher Arquivo' : 'Escolher da Galeria',
                  subtitulo: kIsWeb
                      ? 'Selecionar arquivo do computador'
                      : 'Selecionar foto existente',
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarImagem(ImageSource.gallery);
                  },
                ),
                if (imagemUrl != null && imagemUrl!.isNotEmpty) ...[
                  const Divider(),
                  _buildOpcaoImagem(
                    icone: Icons.delete_outline,
                    titulo: 'Remover Foto',
                    subtitulo: 'Excluir foto atual',
                    cor: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmarRemocaoImagem();
                    },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpcaoImagem({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? cor,
  }) {
    Color corFinal = cor ?? const Color.fromARGB(255, 1, 37, 54);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: corFinal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icone, color: corFinal, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: corFinal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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

  Future<void> _confirmarRemocaoImagem() async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Foto'),
          content:
              const Text('Tem certeza que deseja remover a foto de perfil?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await _removerImagem();
    }
  }

  Future<void> _removerImagemAnterior() async {
    if (imagemUrlOriginal != null &&
        imagemUrlOriginal!.isNotEmpty &&
        imagemUrlOriginal!.contains('firebase')) {
      try {
        print('Removendo imagem anterior: $imagemUrlOriginal');
        Reference ref = _storage.refFromURL(imagemUrlOriginal!);
        await ref.delete();
        print('Imagem anterior removida com sucesso');
      } catch (e) {
        print('Erro ao remover imagem anterior: $e');
      }
    }
  }

  String _tratarMensagemErro(String erro) {
    if (erro.contains('TimeoutException') || erro.contains('timeout')) {
      return 'Tempo limite excedido. Verifique sua conexão.';
    } else if (erro.contains('network') || erro.contains('connection')) {
      return 'Erro de conexão. Verifique sua internet.';
    } else if (erro.contains('authentication') ||
        erro.contains('credentials')) {
      return 'Erro de autenticação. Tente novamente.';
    } else if (erro.contains('permission')) {
      return 'Sem permissão para acessar o serviço.';
    } else if (erro.contains('muito grande')) {
      return 'Imagem muito grande. Escolha uma imagem menor.';
    } else if (erro.contains('storage/object-not-found')) {
      return 'Arquivo não encontrado no servidor.';
    } else if (erro.contains('storage/unauthorized')) {
      return 'Sem autorização para acessar o armazenamento.';
    } else if (erro.contains('storage/canceled') || erro.contains('canceled')) {
      return 'Upload cancelado.';
    } else if (erro.contains('storage/unknown')) {
      return 'Erro desconhecido no servidor.';
    }
    return erro.length > 100 ? 'Erro no upload da imagem' : erro;
  }

  Future<void> _removerImagem() async {
    if (!mounted) return;

    setState(() => isUploadingImage = true);

    try {
      if (mounted) {
        setState(() {
          imagemUrl = null;
          imagemFoiAlterada = true;
        });
        _mostrarSnackBar(
          'Foto removida! Clique em "Salvar Perfil" para confirmar as alterações.',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Erro ao remover imagem: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingImage = false);
      }
    }
  }

  Future<void> salvarPerfil() async {
    if (!perfilKey.currentState!.validate()) return;

    if (isUploadingImage) {
      _mostrarSnackBar('Aguarde o upload da imagem terminar', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        Map<String, dynamic> dadosParaAtualizar = {
          'nome': nomeController.text.trim(),
          'descricao': descricaoController.text.trim(),
          'telefone': telefoneController.text.trim(),
          'whatsapp': whatsappController.text.trim(),
          'endereco': enderecoController.text.trim(),
          'site': siteController.text.trim(),
          'instagram': instagramController.text.trim(),
          'facebook': facebookController.text.trim(),
          'areasAtuacao': areasAtuacao,
          'horarioFuncionamento': horarioFuncionamento,
          'updated_at': Timestamp.now(),
        };

        if (imagemFoiAlterada) {
          if (imagemUrlOriginal != imagemUrl) {
            await _removerImagemAnterior();
          }

          dadosParaAtualizar['imagemUrl'] = imagemUrl;
          dadosParaAtualizar['imagemAtualizadaEm'] =
              FieldValue.serverTimestamp();
        }

        print('Salvando dados no Firestore...');
        await FirebaseFirestore.instance
            .collection('ongs')
            .doc(uid)
            .update(dadosParaAtualizar);

        print('Dados salvos com sucesso');

        if (mounted) {
          _mostrarSnackBar('Perfil atualizado com sucesso!', Colors.green);
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      print('Erro ao salvar perfil: $e');
      if (mounted) {
        _mostrarSnackBar(
          'Erro ao salvar perfil: ${_tratarMensagemErro(e.toString())}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? tipoTeclado,
    int? maxLinhas,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 37, 54),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: tipoTeclado,
          maxLines: maxLinhas ?? 1,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: const Color.fromARGB(255, 1, 37, 54),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 1, 37, 54),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 1, 37, 54),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET DE IMAGEM OTIMIZADO PARA CHROME
  Widget _buildImagemPerfil() {
    return GestureDetector(
      onTap: isUploadingImage ? null : selecionarImagem,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 1, 37, 54),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: isUploadingImage
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color.fromARGB(255, 1, 37, 54),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enviando...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      ),
                    ],
                  ),
                )
              : (imagemUrl != null && imagemUrl!.isNotEmpty)
                  ? Image.network(
                      _getProxiedImageUrl(imagemUrl!),
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
                        print('Erro ao carregar imagem: $error');
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 30,
                              color: Colors.red,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Erro ao\ncarregar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
        ),
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
          SafeArea(
            child: isInitializing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Carregando perfil...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                        const SizedBox(height: 20),
                        Container(
                          width: larguraTela * 0.95,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Form(
                            key: perfilKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'PERFIL DA ONG',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 1, 37, 54),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Foto de perfil OTIMIZADA
                                _buildImagemPerfil(),
                                const SizedBox(height: 10),
                                Text(
                                  isUploadingImage
                                      ? 'Processando imagem...'
                                      : 'Toque para alterar a foto',
                                  style: TextStyle(
                                    color: isUploadingImage
                                        ? Colors.orange
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: isUploadingImage
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Campos de texto
                                campoTexto(
                                  controller: nomeController,
                                  label: "Nome da ONG:",
                                  icon: Icons.business,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "O nome não pode estar vazio"
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: descricaoController,
                                  label: "Descrição da ONG:",
                                  icon: Icons.description,
                                  maxLinhas: 4,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "A descrição não pode estar vazia"
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: telefoneController,
                                  label: "Telefone:",
                                  icon: Icons.phone,
                                  tipoTeclado: TextInputType.phone,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "O telefone não pode estar vazio"
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: whatsappController,
                                  label: "WhatsApp:",
                                  icon: Icons.chat,
                                  tipoTeclado: TextInputType.phone,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: enderecoController,
                                  label: "Endereço completo:",
                                  icon: Icons.location_on,
                                  maxLinhas: 2,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "O endereço não pode estar vazio"
                                          : null,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: siteController,
                                  label: "Site (opcional):",
                                  icon: Icons.web,
                                  tipoTeclado: TextInputType.url,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: instagramController,
                                  label: "Instagram (opcional):",
                                  icon: Icons.camera_alt,
                                ),
                                const SizedBox(height: 20),
                                campoTexto(
                                  controller: facebookController,
                                  label: "Facebook (opcional):",
                                  icon: Icons.facebook,
                                ),
                                const SizedBox(height: 30),

                                // Áreas de atuação
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Áreas de Atuação:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 1, 37, 54),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: areasDisponiveis.map((area) {
                                    bool selecionada =
                                        areasAtuacao.contains(area);
                                    return FilterChip(
                                      label: Text(area),
                                      selected: selecionada,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            areasAtuacao.add(area);
                                          } else {
                                            areasAtuacao.remove(area);
                                          }
                                        });
                                      },
                                      selectedColor:
                                          const Color.fromARGB(255, 1, 37, 54)
                                              .withOpacity(0.3),
                                      checkmarkColor:
                                          const Color.fromARGB(255, 1, 37, 54),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 30),

                                // Horário de funcionamento
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Horário de Funcionamento:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 1, 37, 54),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                ...horarioFuncionamento.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            '${entry.key.capitalize()}:',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: entry.value,
                                            decoration: InputDecoration(
                                              hintText: 'Ex: 08:00 - 17:00',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                            onChanged: (value) {
                                              horarioFuncionamento[entry.key] =
                                                  value;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 40),

                                // Botões
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              255, 1, 37, 54),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        onPressed:
                                            (isLoading || isUploadingImage)
                                                ? null
                                                : salvarPerfil,
                                        child: (isLoading || isUploadingImage)
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              )
                                            : const Text(
                                                "Salvar Perfil",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        onPressed:
                                            (isLoading || isUploadingImage)
                                                ? null
                                                : () {
                                                    _cancelCurrentUpload();
                                                    Navigator.pop(context);
                                                  },
                                        child: const Text(
                                          "Cancelar",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
          // Botão voltar
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              onPressed: () {
                _cancelCurrentUpload();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
