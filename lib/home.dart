import 'package:flutter/material.dart';

class MyTela extends StatefulWidget {
  const MyTela({super.key});

  @override
  State<MyTela> createState() => _MyTelaState();
}

class _MyTelaState extends State<MyTela> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;
    final double alturaTela = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Imagem de fundo com overlay gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fundo.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Container principal com sombra e efeitos
                      Container(
                        width: larguraTela * 0.88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Imagem de topo com gradiente overlay corrigido
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 160,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                            'assets/images/logo.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Container branco principal
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: alturaTela * 0.65,
                              ),
                              padding: const EdgeInsets.all(30),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Título principal com estilo melhorado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color.fromARGB(255, 1, 37, 54),
                                          const Color.fromARGB(255, 1, 37, 54)
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                                  255, 1, 37, 54)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      "PORTAL DAS ONG'S",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Subtítulo melhorado
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Text(
                                      "Seja Bem-Vindo!",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: Color.fromARGB(255, 1, 37, 54),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Botão "Sobre Nós" melhorado
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color:
                                            const Color.fromARGB(255, 1, 37, 54)
                                                .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/SN');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 25,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: const Color.fromARGB(
                                                255, 1, 37, 54),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            "Sobre Nós",
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 1, 37, 54),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: Color.fromARGB(
                                                  255, 1, 37, 54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Botões principais melhorados
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 1, 37, 54)
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/CadUsuario');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 1, 37, 54),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.person_add,
                                                size: 20),
                                            label: const Text(
                                              "Cadastrar-se",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Container(
                                          height: 55,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromARGB(
                                                        255, 1, 37, 54)
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                  context, '/login');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                      255, 1, 37, 54),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.login,
                                                size: 20),
                                            label: const Text(
                                              "Login",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // Rodapé decorativo
                                  Container(
                                    width: 60,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color.fromARGB(255, 1, 37, 54),
                                          const Color.fromARGB(255, 1, 37, 54)
                                              .withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
