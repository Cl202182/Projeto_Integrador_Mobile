import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class VisualizarPerfilOng extends StatefulWidget {
  const VisualizarPerfilOng({super.key});

  @override
  State<VisualizarPerfilOng> createState() => _VisualizarPerfilOngState();
}

class _VisualizarPerfilOngState extends State<VisualizarPerfilOng> {
  Map<String, dynamic>? dadosOng;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarDadosOng();
  }

  // SOLUÇÃO DEFINITIVA: PROXY PARA IMAGENS
  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      // Para web, usar proxy CORS que resolve o problema
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl; // Mobile usa URL original
  }

  Future<void> carregarDadosOng() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          setState(() {
            dadosOng = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
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

  // WIDGET DE IMAGEM OTIMIZADO PARA CHROME
  Widget _buildImagemPerfil() {
    return Container(
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
        child: (dadosOng?['imagemUrl'] != null &&
                dadosOng!['imagemUrl'].toString().isNotEmpty)
            ? Image.network(
                _getProxiedImageUrl(dadosOng!['imagemUrl']),
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
                Icons.business,
                size: 50,
                color: Color.fromARGB(255, 1, 37, 54),
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
                          // Header com nome da ONG
                          Text(
                            dadosOng?['nome'] ?? 'Nome da ONG',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 37, 54),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          // Foto de perfil OTIMIZADA
                          _buildImagemPerfil(),
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
                                Navigator.pushNamed(context, '/editarong');
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
                          const SizedBox(height: 30),

                          // Descrição
                          infoCard(
                            titulo: 'Sobre Nós',
                            conteudo: dadosOng?['descricao']?.isNotEmpty == true
                                ? dadosOng!['descricao']
                                : 'Descrição não informada',
                            icone: Icons.description,
                          ),

                          // Informações de contato
                          infoCard(
                            titulo: 'Contato',
                            icone: Icons.contact_phone,
                            children: [
                              infoItem(Icons.email, 'Email',
                                  dadosOng?['email'] ?? 'Não informado'),
                              infoItem(
                                  Icons.phone,
                                  'Telefone',
                                  dadosOng?['telefone']?.isNotEmpty == true
                                      ? dadosOng!['telefone']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.chat,
                                  'WhatsApp',
                                  dadosOng?['whatsapp']?.isNotEmpty == true
                                      ? dadosOng!['whatsapp']
                                      : 'Não informado'),
                            ],
                          ),

                          // Endereço
                          infoCard(
                            titulo: 'Localização',
                            conteudo: dadosOng?['endereco']?.isNotEmpty == true
                                ? dadosOng!['endereco']
                                : 'Endereço não informado',
                            icone: Icons.location_on,
                          ),

                          // CEP
                          infoCard(
                            titulo: 'CEP',
                            conteudo: dadosOng?['cep']?.isNotEmpty == true
                                ? dadosOng!['cep']
                                : 'CEP não informado',
                            icone: Icons.location_city,
                          ),

                          // CNPJ
                          infoCard(
                            titulo: 'CNPJ',
                            conteudo: dadosOng?['cnpj']?.isNotEmpty == true
                                ? dadosOng!['cnpj']
                                : 'CNPJ não informado',
                            icone: Icons.document_scanner,
                          ),

                          // Redes Sociais
                          infoCard(
                            titulo: 'Redes Sociais',
                            icone: Icons.share,
                            children: [
                              infoItem(
                                  Icons.web,
                                  'Site',
                                  dadosOng?['site']?.isNotEmpty == true
                                      ? dadosOng!['site']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.camera_alt,
                                  'Instagram',
                                  dadosOng?['instagram']?.isNotEmpty == true
                                      ? dadosOng!['instagram']
                                      : 'Não informado'),
                              infoItem(
                                  Icons.facebook,
                                  'Facebook',
                                  dadosOng?['facebook']?.isNotEmpty == true
                                      ? dadosOng!['facebook']
                                      : 'Não informado'),
                            ],
                          ),

                          // Áreas de atuação
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color:
                                          const Color.fromARGB(255, 1, 37, 54),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Áreas de Atuação',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 1, 37, 54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                dadosOng?['areasAtuacao'] != null &&
                                        (dadosOng!['areasAtuacao'] as List)
                                            .isNotEmpty
                                    ? Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (dadosOng!['areasAtuacao']
                                                as List<dynamic>)
                                            .map((area) => Chip(
                                                  label: Text(area.toString()),
                                                  backgroundColor:
                                                      const Color.fromARGB(
                                                              255, 1, 37, 54)
                                                          .withOpacity(0.1),
                                                  labelStyle: const TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 1, 37, 54),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ))
                                            .toList(),
                                      )
                                    : Text(
                                        'Áreas de atuação não informadas',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ],
                            ),
                          ),

                          // Horário de funcionamento
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color:
                                          const Color.fromARGB(255, 1, 37, 54),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Horário de Funcionamento',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 1, 37, 54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._buildTodosHorarios(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
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

  bool _temRedesSociais() {
    return (dadosOng?['site'] != null && dadosOng!['site'].isNotEmpty) ||
        (dadosOng?['instagram'] != null && dadosOng!['instagram'].isNotEmpty) ||
        (dadosOng?['facebook'] != null && dadosOng!['facebook'].isNotEmpty);
  }

  bool _temHorarioFuncionamento() {
    if (dadosOng?['horarioFuncionamento'] == null) return false;

    Map<String, dynamic> horarios = dadosOng!['horarioFuncionamento'];
    return horarios.values
        .any((horario) => horario != null && horario.toString().isNotEmpty);
  }

  List<Widget> _buildTodosHorarios() {
    List<Widget> widgets = [];
    Map<String, String> diasSemana = {
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    diasSemana.forEach((chave, nomeCompleto) {
      String horario = 'Não informado';

      if (dadosOng?['horarioFuncionamento'] != null) {
        Map<String, dynamic> horarios = dadosOng!['horarioFuncionamento'];
        if (horarios[chave] != null && horarios[chave].toString().isNotEmpty) {
          horario = horarios[chave].toString();
        }
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '$nomeCompleto:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 1, 37, 54),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  horario,
                  style: TextStyle(
                    color: horario == 'Não informado'
                        ? Colors.grey[500]
                        : Colors.grey[700],
                    fontStyle: horario == 'Não informado'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  Widget infoCard({
    required String titulo,
    String? conteudo,
    required IconData icone,
    List<Widget>? children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: const Color.fromARGB(255, 1, 37, 54),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 1, 37, 54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (conteudo != null)
            Text(
              conteudo,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget infoItem(IconData icone, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icone,
            size: 20,
            color: const Color.fromARGB(255, 1, 37, 54),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
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
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
