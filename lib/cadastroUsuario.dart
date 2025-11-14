import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/validators.dart';

class cliente extends StatefulWidget {
  const cliente({super.key});

  @override
  State<cliente> createState() => _clienteState();
}

class _clienteState extends State<cliente> {
  GlobalKey<FormState> cliKey = GlobalKey<FormState>();
  TextEditingController nome1 = TextEditingController();
  TextEditingController email1 = TextEditingController();
  TextEditingController senhaController = TextEditingController();
  TextEditingController cpfController = TextEditingController();

  Future<void> gravarBD() async {
    try {
      // Criar usuário no Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email1.text.trim(),
        password: senhaController.text.trim(),
      );

      // Pegar UID do usuário criado
      String uid = userCredential.user!.uid;

      // Salvar dados do cliente no Firestore usando UID como ID do documento
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'nome': nome1.text.trim(),
        'email': email1.text.trim(),
        'cpf': cpfController.text.trim(),
        'tipo': 'cliente',
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );

      nome1.clear();
      email1.clear();
      senhaController.clear();
      cpfController.clear();
      setState(() {});
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cadastro: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fundo.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/');
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    width: larguraTela * 0.9,
                    height: 150,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  width: larguraTela * 0.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Form(
                    key: cliKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CADASTRO DE CLIENTES',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: nome1,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Nome:",
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 1, 37, 54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Nome é obrigatório";
                            } else if (value.trim().length < 2) {
                              return "Nome deve ter pelo menos 2 caracteres";
                            } else if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$')
                                .hasMatch(value)) {
                              return "Nome deve conter apenas letras";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: email1,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email:",
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 1, 37, 54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "O Email é obrigatório";
                            } else if (!Validators.isValidEmail(value)) {
                              return "Por favor, insira um email válido";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: senhaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Senha:',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 1, 37, 54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            return Validators.getPasswordError(value ?? '');
                          },
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          controller: cpfController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'CPF:',
                            labelStyle: const TextStyle(color: Colors.white),
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 1, 37, 54),
                            hintText: '000.000.000-00',
                            hintStyle: const TextStyle(color: Colors.white54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            // Formatação automática do CPF
                            String formatted = Validators.formatCPF(value);
                            if (formatted != value) {
                              cpfController.value =
                                  cpfController.value.copyWith(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CPF é obrigatório';
                            } else if (!Validators.isValidCPF(value)) {
                              return 'CPF inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (cliKey.currentState!.validate()) {
                                      await gravarBD();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 1, 37, 54),
                                  ),
                                  child: const Text(
                                    "Cadastrar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    nome1.clear();
                                    email1.clear();
                                    senhaController.clear();
                                    cpfController.clear();
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 1, 37, 54),
                                  ),
                                  child: const Text(
                                    "Cancelar",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Você é uma ONG? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/CadOng');
                              },
                              child: const Text(
                                "Cadastre-se aqui!",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Color.fromARGB(255, 1, 37, 54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
