import 'package:flutter/material.dart';

class HomeONG extends StatelessWidget {
  const HomeONG({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ONG'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.post_add),
            tooltip: 'Ir para Postagem',
            onPressed: () {
              Navigator.pushNamed(context, '/postagem');
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Ir para Chat',
            onPressed: () {
              Navigator.pushNamed(context, '/contatoOng');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/visong');
              },
              icon: const Icon(Icons.account_circle),
              label: const Text('Visualizar Perfil da ONG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
