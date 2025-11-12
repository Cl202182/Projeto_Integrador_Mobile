import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_projeto_integrador/components/bottom_nav_bar.dart';

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
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    _enderecoController.dispose();
    _cepController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
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
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context, true); // Retorna true para indicar sucesso
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: $e')),
        );
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
