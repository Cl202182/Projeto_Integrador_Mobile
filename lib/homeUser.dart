import 'package:flutter/material.dart';

class HomeUser extends StatelessWidget {
  const HomeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo Usuário'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Ir para Chat',
            onPressed: () {
              Navigator.pushNamed(context, '/contatoUser');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}
