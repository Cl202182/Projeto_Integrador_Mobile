import 'package:flutter/material.dart';

class HomeONG extends StatelessWidget {
  const HomeONG({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ONG'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Hello, ONG!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
