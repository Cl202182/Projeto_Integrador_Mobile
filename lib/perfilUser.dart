import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  Map<String, dynamic>? dadosUsuario;
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
          setState(() {
            dadosUsuario = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() {
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

                          // Avatar
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
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color.fromARGB(255, 1, 37, 54),
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

                          // Áreas de interesse
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
                                      Icons.favorite,
                                      color:
                                          const Color.fromARGB(255, 1, 37, 54),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Áreas de Interesse',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 1, 37, 54),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                dadosUsuario?['areasInteresse'] != null &&
                                        (dadosUsuario!['areasInteresse']
                                                as List)
                                            .isNotEmpty
                                    ? Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (dadosUsuario![
                                                    'areasInteresse']
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
                                        'Áreas de interesse não informadas',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ],
                            ),
                          ),

                          // Informações de conta
                          infoCard(
                            titulo: 'Informações da Conta',
                            conteudo:
                                'Membro desde ${_formatarDataCadastro(dadosUsuario?['created_at'])}',
                            icone: Icons.calendar_today,
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
  late TextEditingController _telefoneController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _enderecoController;
  late TextEditingController _cepController;
  List<String> _areasInteresse = [];
  bool _isLoading = false;

  // Áreas disponíveis para seleção
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
    _nomeController =
        TextEditingController(text: widget.dadosUsuario?['nome'] ?? '');
    _cpfController =
        TextEditingController(text: widget.dadosUsuario?['cpf'] ?? '');
    _telefoneController =
        TextEditingController(text: widget.dadosUsuario?['telefone'] ?? '');
    _dataNascimentoController = TextEditingController(
        text: widget.dadosUsuario?['dataNascimento'] ?? '');
    _enderecoController =
        TextEditingController(text: widget.dadosUsuario?['endereco'] ?? '');
    _cepController =
        TextEditingController(text: widget.dadosUsuario?['cep'] ?? '');
    _areasInteresse =
        List<String>.from(widget.dadosUsuario?['areasInteresse'] ?? []);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    _enderecoController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'nome': _nomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'dataNascimento': _dataNascimentoController.text.trim(),
          'endereco': _enderecoController.text.trim(),
          'cep': _cepController.text.trim(),
          'areasInteresse': _areasInteresse,
          'updated_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Color.fromARGB(255, 1, 37, 54),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarData() async {
    DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataNascimentoController.text =
            '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}';
      });
    }
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType tipoTeclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
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
                  Container(
                    width: larguraTela * 0.95,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'EDITAR PERFIL',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 1, 37, 54),
                            ),
                          ),
                          const SizedBox(height: 30),

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
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Color.fromARGB(255, 1, 37, 54),
                            ),
                          ),
                          const SizedBox(height: 30),

                          campoTexto(
                            controller: _nomeController,
                            label: "Nome Completo:",
                            icon: Icons.person,
                            validator: (value) => value == null || value.isEmpty
                                ? "O nome não pode estar vazio"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          campoTexto(
                            controller: _cpfController,
                            label: "CPF:",
                            icon: Icons.credit_card,
                            tipoTeclado: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "O CPF não pode estar vazio";
                              }
                              if (value
                                      .replaceAll(RegExp(r'[^0-9]'), '')
                                      .length !=
                                  11) {
                                return "CPF deve ter 11 dígitos";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          campoTexto(
                            controller: _telefoneController,
                            label: "Telefone:",
                            icon: Icons.phone,
                            tipoTeclado: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          // Campo de data com seletor
                          TextFormField(
                            controller: _dataNascimentoController,
                            readOnly: true,
                            onTap: _selecionarData,
                            decoration: InputDecoration(
                              labelText: "Data de Nascimento:",
                              labelStyle: const TextStyle(color: Colors.white),
                              prefixIcon:
                                  const Icon(Icons.cake, color: Colors.white70),
                              suffixIcon: const Icon(Icons.calendar_today,
                                  color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 1, 37, 54),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 1, 37, 54)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          campoTexto(
                            controller: _enderecoController,
                            label: "Endereço:",
                            icon: Icons.home,
                          ),
                          const SizedBox(height: 20),

                          campoTexto(
                            controller: _cepController,
                            label: "CEP:",
                            icon: Icons.location_city,
                            tipoTeclado: TextInputType.number,
                          ),
                          const SizedBox(height: 30),

                          // Áreas de interesse
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Áreas de Interesse:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 1, 37, 54),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 1, 37, 54)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color.fromARGB(255, 1, 37, 54)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: areasDisponiveis.map((area) {
                                    bool selecionada =
                                        _areasInteresse.contains(area);
                                    return FilterChip(
                                      label: Text(area),
                                      selected: selecionada,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            _areasInteresse.add(area);
                                          } else {
                                            _areasInteresse.remove(area);
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

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
                                  onPressed:
                                      _isLoading ? null : _salvarAlteracoes,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          "Salvar",
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
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.pop(context),
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
}
