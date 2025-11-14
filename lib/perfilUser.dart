import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'components/bottom_nav_bar.dart';
import 'image_service.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

// Função para abrir a tela de chat com uma ONG
void _abrirChatComOng(BuildContext context, String ongId, String ongNome) {
  Navigator.pushNamed(
    context,
    '/chat',
    arguments: {
      'chatId': '${FirebaseAuth.instance.currentUser?.uid}_$ongId',
      'userId': ongId,
      'userName': ongNome,
      'userType': 'ong',
    },
  );
}

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  Map<String, dynamic>? dadosUsuario;
  String? userImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();
  }

  Future<void> carregarDadosUsuario() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          print('📸 Dados do usuário carregados: ${dados['imagemUrl']}');
          setState(() {
            dadosUsuario = dados;
            userImageUrl = dados['imagemUrl'];
            isLoading = false;
          });
        } else {
          setState(() {
            userImageUrl = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2, // Índice 2 para a aba de perfil
        isOng: false,
        profileImageUrl: userImageUrl,
      ),
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
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Container principal
                    Container(
                      width: larguraTela * 0.95,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header com nome do usuário
                          Text(
                            dadosUsuario?['nome'] ?? 'Nome do Usuário',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 37, 54),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Avatar com foto de perfil
                          Container(
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
                              child: (dadosUsuario?['imagemUrl'] != null &&
                                      dadosUsuario!['imagemUrl']
                                          .toString()
                                          .isNotEmpty)
                                  ? SmartImage(
                                      imageUrl: dadosUsuario!['imagemUrl'],
                                      width: 120,
                                      height: 120,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Color.fromARGB(255, 1, 37, 54),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Botão Editar Perfil
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 1, 37, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarPerfilUsuario(
                                        dadosUsuario: dadosUsuario),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    carregarDadosUsuario();
                                  }
                                });
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text(
                                "Editar Perfil",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Botão Sair
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () async {
                                // Mostrar diálogo de confirmação
                                bool? confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Sair da Conta'),
                                      content: const Text(
                                          'Tem certeza que deseja sair?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            'Sair',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmar == true) {
                                  await FirebaseAuth.instance.signOut();
                                  if (mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              icon:
                                  const Icon(Icons.logout, color: Colors.white),
                              label: const Text(
                                "Sair da Conta",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Informações pessoais
                          infoCard(
                            titulo: 'Informações Pessoais',
                            icone: Icons.person,
                            children: [
                              infoItem(Icons.email, 'Email',
                                  dadosUsuario?['email'] ?? 'Não informado'),
                              infoItem(
                                  Icons.credit_card,
                                  'CPF',
                                  dadosUsuario?['cpf']?.isNotEmpty == true
                                      ? dadosUsuario!['cpf']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.phone,
                                  'Telefone',
                                  dadosUsuario?['telefone']?.isNotEmpty == true
                                      ? dadosUsuario!['telefone']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.cake,
                                  'Data de Nascimento',
                                  dadosUsuario?['dataNascimento']?.isNotEmpty ==
                                          true
                                      ? dadosUsuario!['dataNascimento']
                                      : 'Não informado'),
                            ],
                          ),

                          // Endereço
                          infoCard(
                            titulo: 'Endereço',
                            icone: Icons.location_on,
                            children: [
                              infoItem(
                                  Icons.home,
                                  'Endereço',
                                  dadosUsuario?['endereco']?.isNotEmpty == true
                                      ? dadosUsuario!['endereco']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.location_city,
                                  'CEP',
                                  dadosUsuario?['cep']?.isNotEmpty == true
                                      ? dadosUsuario!['cep']
                                      : 'Não informado'),
                            ],
                          ),

                          // Data de cadastro
                          infoCard(
                            titulo: 'Conta',
                            icone: Icons.calendar_today,
                            children: [
                              infoItem(
                                  Icons.calendar_today,
                                  'Membro desde',
                                  dadosUsuario?['dataCadastro'] != null
                                      ? _formatarDataCadastro(
                                          dadosUsuario!['dataCadastro'])
                                      : 'Data não informada'),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget infoCard(
      {required String titulo,
      required IconData icone,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: const Color.fromARGB(255, 1, 37, 54),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 1, 37, 54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget infoItem(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icone,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Text(
            '$titulo: ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 1, 37, 54),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: valor == 'Não informado'
                    ? Colors.grey[500]
                    : Colors.grey[700],
                fontStyle: valor == 'Não informado'
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
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
}

// Tela de edição simplificada
class EditarPerfilUsuario extends StatefulWidget {
  final Map<String, dynamic>? dadosUsuario;

  const EditarPerfilUsuario({super.key, this.dadosUsuario});

  @override
  State<EditarPerfilUsuario> createState() => _EditarPerfilUsuarioState();
}

class _EditarPerfilUsuarioState extends State<EditarPerfilUsuario> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _cpfController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _enderecoController;
  late TextEditingController _cepController;
  bool _isLoading = false;
  bool _isSaving = false;

  // Variáveis para gerenciar imagem
  String? imagemUrl;
  String? imagemUrlOriginal;
  bool isUploadingImage = false;
  bool imagemFoiAlterada = false;

  // Serviços
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: 'gs://portal-ongs.firebasestorage.app');

  // Controle de upload
  UploadTask? _currentUploadTask;
  StreamSubscription<TaskSnapshot>? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: widget.dadosUsuario?['nome'] ?? '');
    _cpfController =
        TextEditingController(text: widget.dadosUsuario?['cpf'] ?? '');
    _emailController =
        TextEditingController(text: widget.dadosUsuario?['email'] ?? '');
    _telefoneController =
        TextEditingController(text: widget.dadosUsuario?['telefone'] ?? '');
    _dataNascimentoController = TextEditingController(
        text: widget.dadosUsuario?['dataNascimento'] ?? '');
    _enderecoController =
        TextEditingController(text: widget.dadosUsuario?['endereco'] ?? '');
    _cepController =
        TextEditingController(text: widget.dadosUsuario?['cep'] ?? '');

    // Carregar imagem do usuário
    imagemUrlOriginal = widget.dadosUsuario?['imagemUrl'];
    imagemUrl = widget.dadosUsuario?['imagemUrl'];
  }

  @override
  void dispose() {
    _cancelCurrentUpload();
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    _enderecoController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  void _cancelCurrentUpload() {
    _uploadSubscription?.cancel();
    _currentUploadTask?.cancel();
    _currentUploadTask = null;
    _uploadSubscription = null;
  }

  // PROXY PARA IMAGENS (mesmo padrão da ONG)
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
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

      // Solicitar permissões antes de tentar acessar câmera/galeria
      PermissionStatus permission;
      if (source == ImageSource.camera) {
        permission = await Permission.camera.request();
        if (permission != PermissionStatus.granted) {
          _mostrarSnackBar('Permissão de câmera necessária', Colors.red);
          return;
        }
      } else {
        // Para galeria, verificar permissões
        PermissionStatus photosStatus = await Permission.photos.status;
        PermissionStatus storageStatus = await Permission.storage.status;

        if (photosStatus != PermissionStatus.granted &&
            storageStatus != PermissionStatus.granted) {
          Map<Permission, PermissionStatus> permissions = await [
            Permission.photos,
            Permission.storage,
          ].request();

          if (permissions[Permission.photos] != PermissionStatus.granted &&
              permissions[Permission.storage] != PermissionStatus.granted) {
            _mostrarSnackBar('Permissão de galeria necessária', Colors.red);
            return;
          }
        }
      }

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
          _mostrarSnackBar('Imagem muito grande. Máximo 5MB.', Colors.red);
          return;
        }

        final bytes = await image.readAsBytes();
        await _processarImagemComDiagnostico(bytes);
      } else {
        print('❌ Nenhuma imagem selecionada');
      }
    } catch (e) {
      print('💥 Erro ao selecionar imagem: $e');
      _mostrarSnackBar('Erro ao selecionar imagem', Colors.red);
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
          _mostrarSnackBar(
              'Foto atualizada! Clique em "Salvar" para confirmar.',
              Colors.green);
        }
      } else {
        throw Exception('URL da imagem está vazia');
      }
    } catch (e) {
      print('💥 Erro no processamento: $e');
      _mostrarSnackBar('Erro ao processar imagem: $e', Colors.red);
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

      Reference ref = _storage.ref().child('users/perfil/$fileName');
      print('📍 Caminho: ${ref.fullPath}');

      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
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
          'Foto removida! Clique em "Salvar" para confirmar as alterações.',
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

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    if (isUploadingImage) {
      _mostrarSnackBar('Aguarde o upload da imagem terminar', Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        Map<String, dynamic> dadosParaAtualizar = {
          'nome': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'dataNascimento': _dataNascimentoController.text.trim(),
          'endereco': _enderecoController.text.trim(),
          'cep': _cepController.text.trim(),
          'dataAtualizacao': FieldValue.serverTimestamp(),
        };

        // Se a imagem foi alterada, atualizar no Firestore
        if (imagemFoiAlterada) {
          if (imagemUrlOriginal != imagemUrl) {
            await _removerImagemAnterior();
          }

          dadosParaAtualizar['imagemUrl'] = imagemUrl;
          dadosParaAtualizar['imagemAtualizadaEm'] =
              FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(dadosParaAtualizar);

        if (mounted) {
          _mostrarSnackBar('Perfil atualizado com sucesso!', Colors.green);
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.pop(context, true); // Retorna true para indicar sucesso
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Erro ao salvar alterações: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 1, 37, 54),
              onPrimary: Colors.white,
              onSurface: Color.fromARGB(255, 1, 37, 54),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 1, 37, 54),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      final formattedDate =
          '${dataSelecionada.day.toString().padLeft(2, '0')}/' +
              '${dataSelecionada.month.toString().padLeft(2, '0')}/' +
              '${dataSelecionada.year}';

      setState(() {
        _dataNascimentoController.text = formattedDate;
      });
    }
  }

  // Widget de imagem de perfil (mesmo padrão da ONG)
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
                      Icons.person,
                      size: 50,
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
        ),
      ),
    );
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType tipoTeclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: tipoTeclado,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: const Color.fromARGB(255, 1, 37, 54),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 1, 37, 54),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey[400]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 1, 37, 54),
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(
            color: Color.fromARGB(255, 1, 37, 54),
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, preencha este campo';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Foto de perfil
                    Center(child: _buildImagemPerfil()),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        isUploadingImage
                            ? 'Processando imagem...'
                            : 'Toque para alterar a foto',
                        style: TextStyle(
                          color: isUploadingImage ? Colors.orange : Colors.grey,
                          fontSize: 12,
                          fontWeight: isUploadingImage
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Campo Nome
                    campoTexto(
                      controller: _nomeController,
                      label: 'Nome Completo',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                    ),

                    // Campo CPF
                    campoTexto(
                      controller: _cpfController,
                      label: 'CPF',
                      icon: Icons.credit_card,
                      tipoTeclado: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu CPF';
                        }
                        // Validação simples de CPF (apenas verifica se tem 11 dígitos)
                        if (value.replaceAll(RegExp(r'[^0-9]'), '').length !=
                            11) {
                          return 'CPF inválido';
                        }
                        return null;
                      },
                    ),

                    // Campo Email (somente leitura)
                    AbsorbPointer(
                      child: campoTexto(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.email,
                        tipoTeclado: TextInputType.emailAddress,
                      ),
                    ),

                    // Campo Telefone
                    campoTexto(
                      controller: _telefoneController,
                      label: 'Telefone',
                      icon: Icons.phone,
                      tipoTeclado: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu telefone';
                        }
                        return null;
                      },
                    ),

                    // Campo Data de Nascimento
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _dataNascimentoController,
                        readOnly: true,
                        onTap: _selecionarData,
                        decoration: InputDecoration(
                          labelText: 'Data de Nascimento',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color.fromARGB(255, 1, 37, 54),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 1, 37, 54),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey[400]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 1, 37, 54),
                              width: 2,
                            ),
                          ),
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 1, 37, 54),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione sua data de nascimento';
                          }
                          return null;
                        },
                      ),
                    ),

                    // Campo Endereço
                    campoTexto(
                      controller: _enderecoController,
                      label: 'Endereço',
                      icon: Icons.home,
                    ),

                    // Campo CEP
                    campoTexto(
                      controller: _cepController,
                      label: 'CEP',
                      icon: Icons.location_on,
                      tipoTeclado: TextInputType.number,
                    ),

                    const SizedBox(height: 30),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _isSaving ? null : _salvarAlteracoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SALVAR ALTERAÇÕES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
