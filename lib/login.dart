import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({super.key});

  @override
  State<MyLogin> createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController loginController = TextEditingController();
  TextEditingController senhaController = TextEditingController();
  bool _obscureSenha = true;

  Future<void> fazerLogin(String email, String senha) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);

      final uid = userCredential.user!.uid;

      final DocumentSnapshot ongDoc =
          await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (ongDoc.exists && userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro: Conta está duplicada em ONG e Usuário')),
        );
        return;
      }

      if (ongDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado como ONG.')),
        );
        Navigator.pushReplacementNamed(context, '/hong');
        return;
      }

      if (userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado como Usuário.')),
        );
        Navigator.pushReplacementNamed(context, '/hong');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Conta autenticada, mas não encontrada no sistema.')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;

      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMsg = 'Email ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Formato de email inválido.';
      } else {
        errorMsg = 'Erro no login: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado no login.')),
      );
    }
  }

  void _mostrarDialogoRedefinirSenha() {
    final TextEditingController emailResetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Redefinir senha"),
          content: TextField(
            controller: emailResetController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Digite seu email",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailResetController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Digite um email válido.")),
                  );
                  return;
                }
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Email de redefinição enviado. Verifique sua caixa de entrada.")),
                  );
                } on FirebaseAuthException catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erro: ${e.message}"),
                    ),
                  );
                }
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
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
                    constraints: const BoxConstraints(minHeight: 600),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          campoTexto(
                            controller: loginController,
                            label: "Email:",
                            icon: Icons.email,
                            tipoTeclado: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Por favor, insira seu email";
                              } else if (!RegExp(
                                      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                  .hasMatch(value)) {
                                return "Email inválido";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          campoTexto(
                            controller: senhaController,
                            label: "Senha:",
                            icon: Icons.lock,
                            obscure: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Por favor, insira sua senha";
                              } else if (value.length < 6) {
                                return "A senha deve ter pelo menos 6 caracteres";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _mostrarDialogoRedefinirSenha,
                              child: const Text(
                                "Esqueci minha senha",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 1, 37, 54),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                    if (_formKey.currentState!.validate()) {
                                      fazerLogin(
                                        loginController.text.trim(),
                                        senhaController.text.trim(),
                                      );
                                    }
                                  },
                                  child: const Text("Login",
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
                                    loginController.clear();
                                    senhaController.clear();
                                  },
                                  child: const Text("Cancelar",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Não é cadastrado?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/CadUsuario');
                                },
                                child: const Text(
                                  "Clique aqui!",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 1, 37, 54),
                                    decoration: TextDecoration.underline,
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
            top: 30,
            left: 0,
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
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
  }) {
    final bool isSenha = label.toLowerCase().contains("senha");

    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      obscureText: isSenha ? _obscureSenha : obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon),
        suffixIcon: isSenha
            ? IconButton(
                icon: Icon(
                  _obscureSenha ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSenha = !_obscureSenha;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 1, 37, 54),
      ),
      style: const TextStyle(color: Colors.white),
      validator: validator,
    );
  }
}
