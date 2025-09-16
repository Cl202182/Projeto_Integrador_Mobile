import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeONG extends StatefulWidget {
  const HomeONG({super.key});

  @override
  State<HomeONG> createState() => _HomeONGState();
}

class _HomeONGState extends State<HomeONG> {
  String? nomeOng;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarNomeOng();
  }

  Future<void> _carregarNomeOng() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('ongs').doc(uid).get();

        if (doc.exists) {
          Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
          setState(() {
            nomeOng = dados['nome'] ?? 'ONG';
            isLoading = false;
          });
        } else {
          setState(() {
            nomeOng = 'ONG';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        nomeOng = 'ONG';
        isLoading = false;
      });
    }
  }

  void _visualizarPerfil() {
    Navigator.pushNamed(context, '/visong');
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
                  Icons.business,
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
                      isLoading ? 'Carregando...' : 'Bem-vindo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      isLoading ? '' : nomeOng ?? 'ONG',
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
            icon: const Icon(Icons.post_add),
            tooltip: 'Ir para Postagem',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/postagem');
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Ir para Chat',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/contatoOng');
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
        child: const Center(
          child: Text(
            'Área de conteúdo principal',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
