import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Contato extends StatefulWidget {
  const Contato({super.key});

  @override
  State<Contato> createState() => _ContatoState();
}

class _ContatoState extends State<Contato> {
  final String currentOngId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários da ONG'),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar usuários.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final userName = userData['nome'] ?? 'Usuário sem nome';

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 1, 37, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    String chatId = generateChatId(currentOngId, userId);

                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'chatId': chatId,
                        'userName': userName,
                        'userId': userId,
                      },
                    );
                  },
                  child: Text(
                    '$userName',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String generateChatId(String id1, String id2) {
    return (id1.hashCode <= id2.hashCode) ? '${id1}_$id2' : '${id2}_$id1';
  }
}
