import 'package:flutter/material.dart';

class TelaChat extends StatelessWidget {
  const TelaChat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de Chat'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Conteúdo da página de Chat',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
