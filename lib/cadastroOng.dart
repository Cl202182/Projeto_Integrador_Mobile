import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/validators.dart';

class ong extends StatefulWidget {
  const ong({super.key});

  @override
  State<ong> createState() => _ongState();
}

class _ongState extends State<ong> {
  GlobalKey<FormState> ongKey = GlobalKey<FormState>();
  TextEditingController nome1 = TextEditingController();
  TextEditingController email1 = TextEditingController();
  TextEditingController cnpj1 = TextEditingController();
  TextEditingController senha1 = TextEditingController();
  TextEditingController cep1 = TextEditingController();

  Future<void> gravarBD() async {
    try {
      // Criar usuário no Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email1.text.trim(),
        password: senha1.text.trim(),
      );

      // Pega o UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salvar dados da ONG no Firestore com o UID como id do documento
      await FirebaseFirestore.instance.collection('ongs').doc(uid).set({
        "nome": nome1.text.trim(),
        "email": email1.text.trim(),
        "cnpj": cnpj1.text.trim(),
        "cep": cep1.text.trim(),
        "tipo": "ong",
        "created_at": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ONG cadastrada com sucesso!')),
      );

      nome1.clear();
      email1.clear();
      cnpj1.clear();
      senha1.clear();
      cep1.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cadastro: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar ONG: $e')),
      );
    }
    setState(() {});
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
                    child: Form(
                      key: ongKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'CADASTRO DE ONGS',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Nome
                          campoTexto(
                            controller: nome1,
                            label: "Nome:",
                            icon: Icons.badge,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Nome da ONG é obrigatório";
                              } else if (value.trim().length < 3) {
                                return "Nome deve ter pelo menos 3 caracteres";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // Email
                          campoTexto(
                            controller: email1,
                            label: "Email:",
                            icon: Icons.email,
                            tipoTeclado: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email é obrigatório";
                              } else if (!Validators.isValidEmail(value)) {
                                return "Por favor, insira um email válido";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // CNPJ
                          campoTexto(
                            controller: cnpj1,
                            label: "CNPJ:",
                            icon: Icons.document_scanner,
                            tipoTeclado: TextInputType.number,
                            hintText: '00.000.000/0000-00',
                            onChanged: (value) {
                              // Formatação automática do CNPJ
                              String formatted = Validators.formatCNPJ(value);
                              if (formatted != value) {
                                cnpj1.value = cnpj1.value.copyWith(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "CNPJ é obrigatório";
                              } else if (!Validators.isValidCNPJ(value)) {
                                return "CNPJ inválido";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // Senha
                          campoTexto(
                            controller: senha1,
                            label: "Senha:",
                            icon: Icons.lock,
                            obscure: true,
                            validator: (value) {
                              return Validators.getPasswordError(value ?? '');
                            },
                          ),

                          const SizedBox(height: 30),

                          // CEP
                          campoTexto(
                            controller: cep1,
                            label: "CEP:",
                            icon: Icons.location_on,
                            tipoTeclado: TextInputType.number,
                            hintText: '00000-000',
                            onChanged: (value) {
                              // Formatação automática do CEP
                              String formatted = Validators.formatCEP(value);
                              if (formatted != value) {
                                cep1.value = cep1.value.copyWith(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                      offset: formatted.length),
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "CEP é obrigatório";
                              } else if (!Validators.isValidCEP(value)) {
                                return "CEP inválido";
                              }
                              return null;
                            },
                          ),

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
                                  onPressed: () {
                                    if (ongKey.currentState!.validate()) {
                                      gravarBD();
                                    }
                                  },
                                  child: const Text("Cadastrar",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 20),
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
                                  onPressed: () {
                                    nome1.clear();
                                    email1.clear();
                                    cnpj1.clear();
                                    senha1.clear();
                                    cep1.clear();
                                  },
                                  child: const Text("Cancelar",
                                      style: TextStyle(color: Colors.white)),
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
            top: 30,
            left: 0,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/registro');
              },
              icon: Icon(
                Icons.arrow_forward,
                color: Colors.white.withOpacity(0.5),
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
    required String? Function(String?) validator,
    String? hintText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 1, 37, 54),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
    );
  }
}
