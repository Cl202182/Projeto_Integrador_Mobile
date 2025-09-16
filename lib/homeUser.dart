import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  String? nomeUsuario;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
  }

  Future<void> _carregarNomeUsuario() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            nomeUsuario = dados['nome'] ?? 'Usuário';
            isLoading = false;
          });
        } else {
          setState(() {
            nomeUsuario = 'Usuário';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        nomeUsuario = 'Usuário';
        isLoading = false;
      });
    }
  }

  void _visualizarPerfil() {
    Navigator.pushNamed(
        context, '/perfilUser'); // Ajuste a rota conforme necessário
  }

  String _getPrimeiroNome() {
    if (nomeUsuario == null || nomeUsuario!.isEmpty) return 'Usuário';
    return nomeUsuario!.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _visualizarPerfil,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoading ? 'Carregando...' : 'Olá',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      isLoading ? '' : _getPrimeiroNome(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Ir para Chat',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/contatoUser');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Ver Perfil',
            color: Colors.white,
            onPressed: _visualizarPerfil,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
      ),
    );
  }
}
