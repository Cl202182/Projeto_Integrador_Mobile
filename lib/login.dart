import 'package:flutter/material.dart';
import 'package:flutter_application_projeto_integrador/loginDados.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  State<MyLogin> createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController loginController = TextEditingController();
  TextEditingController senhaController = TextEditingController();


  List<DadosL> ListaDeCredenciais = [
    DadosL('usuario1', 'senha1'),
    DadosL('usuario2', 'senha2'),
  ];

  bool validarCredenciais(String login, String senha) {
    for (var credencial in ListaDeCredenciais) {
      if (credencial.login == login && credencial.senha == senha) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //IMAGEM DE FUNDO
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
          //TELA BRANCA NA FRENTE DA IMAGEM
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.90,
              width: MediaQuery.of(context).size.width * 0.99,
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 200),
                      TextFormField(
                        controller: loginController,
                        decoration: InputDecoration(
                          labelText: 'Login',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          filled: true,
                          fillColor:  Colors.blue,
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Por favor, insira seu login';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: senhaController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          filled: true,
                          fillColor:  Colors.blue
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Por favor, insira sua senha';
                          } else {
                            if (value.length < 3) {
                              return "A senha deve ter pelo menos 3 caracteres";
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                String login = loginController.text;
                                String senha = senhaController.text;
                                if (validarCredenciais(login, senha)) {
                                  print('Credenciais válidas. Faça algo aqui.');
                                  
                                } else {
                                  print('Credenciais inválidas. Tente novamente.');
                                }
                              }
                            },
                            child: Text("Login"),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              loginController.text = "";
                              senhaController.text = "";
                              setState(() {});
                            },
                            child: Text("Cancelar"),
                          )
                        ],
                      ),
                      SizedBox(height: 20),
                      Text("Não é cadastrado? Clique aqui"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //BANNER DO APP
          Center(
            child: Column(
              children: [
                SizedBox(height: 30),
                FractionallySizedBox(
                  widthFactor: 0.99,
                  child: Container(
                    height: 150,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}