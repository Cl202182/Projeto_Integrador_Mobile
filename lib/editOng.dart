import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool isLoading = false;
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
    carregarDadosPerfil();
  }

  Future<void> carregarDadosPerfil() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            nomeController.text = dados['nome'] ?? '';
            descricaoController.text = dados['descricao'] ?? '';
            telefoneController.text = dados['telefone'] ?? '';
            whatsappController.text = dados['whatsapp'] ?? '';
            enderecoController.text = dados['endereco'] ?? '';
            siteController.text = dados['site'] ?? '';
            instagramController.text = dados['instagram'] ?? '';
            facebookController.text = dados['facebook'] ?? '';
            imagemUrl = dados['imagemUrl'];
            areasAtuacao = List<String>.from(dados['areasAtuacao'] ?? []);

            if (dados['horarioFuncionamento'] != null) {
              horarioFuncionamento =
                  Map<String, String>.from(dados['horarioFuncionamento']);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  Future<void> selecionarImagem() async {
    // Por enquanto, vamos simular a seleção de imagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Funcionalidade de imagem será implementada posteriormente'),
      ),
    );
  }

  Future<String?> uploadImagem() async {
    // Retorna a URL atual da imagem
    return imagemUrl;
  }

  Future<void> salvarPerfil() async {
    if (!perfilKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? novaImagemUrl = await uploadImagem();
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        await FirebaseFirestore.instance.collection('ongs').doc(uid).update({
          'nome': nomeController.text.trim(),
          'descricao': descricaoController.text.trim(),
          'telefone': telefoneController.text.trim(),
          'whatsapp': whatsappController.text.trim(),
          'endereco': enderecoController.text.trim(),
          'site': siteController.text.trim(),
          'instagram': instagramController.text.trim(),
          'facebook': facebookController.text.trim(),
          'imagemUrl': novaImagemUrl,
          'areasAtuacao': areasAtuacao,
          'horarioFuncionamento': horarioFuncionamento,
          'updated_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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

                          // Foto de perfil
                          GestureDetector(
                            onTap: selecionarImagem,
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
                                child: imagemUrl != null
                                    ? Image.network(
                                        imagemUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.camera_alt,
                                            size: 50,
                                            color:
                                                Color.fromARGB(255, 1, 37, 54),
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
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Toque para alterar a foto',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Nome da ONG
                          campoTexto(
                            controller: nomeController,
                            label: "Nome da ONG:",
                            icon: Icons.business,
                            validator: (value) => value == null || value.isEmpty
                                ? "O nome não pode estar vazio"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Descrição
                          campoTexto(
                            controller: descricaoController,
                            label: "Descrição da ONG:",
                            icon: Icons.description,
                            maxLinhas: 4,
                            validator: (value) => value == null || value.isEmpty
                                ? "A descrição não pode estar vazia"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Telefone
                          campoTexto(
                            controller: telefoneController,
                            label: "Telefone:",
                            icon: Icons.phone,
                            tipoTeclado: TextInputType.phone,
                            validator: (value) => value == null || value.isEmpty
                                ? "O telefone não pode estar vazio"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // WhatsApp
                          campoTexto(
                            controller: whatsappController,
                            label: "WhatsApp:",
                            icon: Icons.chat,
                            tipoTeclado: TextInputType.phone,
                            validator: null,
                          ),
                          const SizedBox(height: 20),

                          // Endereço
                          campoTexto(
                            controller: enderecoController,
                            label: "Endereço completo:",
                            icon: Icons.location_on,
                            maxLinhas: 2,
                            validator: (value) => value == null || value.isEmpty
                                ? "O endereço não pode estar vazio"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Site
                          campoTexto(
                            controller: siteController,
                            label: "Site (opcional):",
                            icon: Icons.web,
                            tipoTeclado: TextInputType.url,
                            validator: null,
                          ),
                          const SizedBox(height: 20),

                          // Instagram
                          campoTexto(
                            controller: instagramController,
                            label: "Instagram (opcional):",
                            icon: Icons.camera_alt,
                            validator: null,
                          ),
                          const SizedBox(height: 20),

                          // Facebook
                          campoTexto(
                            controller: facebookController,
                            label: "Facebook (opcional):",
                            icon: Icons.facebook,
                            validator: null,
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
                              bool selecionada = areasAtuacao.contains(area);
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
                                        horarioFuncionamento[entry.key] = value;
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
                                    backgroundColor:
                                        const Color.fromARGB(255, 1, 37, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  onPressed: isLoading ? null : salvarPerfil,
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          "Salvar Perfil",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () {
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

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType tipoTeclado = TextInputType.text,
    bool obscure = false,
    int maxLinhas = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      obscureText: obscure,
      maxLines: maxLinhas,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 1, 37, 54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color.fromARGB(255, 1, 37, 54)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
