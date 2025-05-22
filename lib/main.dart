import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_projeto_integrador/cadastroOng.dart';
import 'package:flutter_application_projeto_integrador/cadastroUsuario.dart';
import 'package:flutter_application_projeto_integrador/home.dart';
import 'package:flutter_application_projeto_integrador/homeOng.dart';
import 'package:flutter_application_projeto_integrador/infoOng.dart';
import 'package:flutter_application_projeto_integrador/login.dart';
import 'package:flutter_application_projeto_integrador/postagem.dart';
import 'package:flutter_application_projeto_integrador/sobrenos.dart';
import 'package:flutter_application_projeto_integrador/telaChat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBnPQAWc1KPYnDqrwouvAgko21_Eqyk46I",
      authDomain: "portal-ongs.firebaseapp.com",
      databaseURL: "https://portal-ongs-default-rtdb.firebaseio.com",
      projectId: "portal-ongs",
      storageBucket: "portal-ongs.appspot.com",
      messagingSenderId: "350051013789",
      appId: "1:350051013789:web:a49ec9bd8b2af7e37f7074",
      measurementId: "G-S979MLVQCW",
    ),
  );

  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInAnonymously();
    print(' Firebase conectado! UID anônimo: ${userCredential.user?.uid}');
  } catch (e) {
    print(' Erro ao conectar com Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web + Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => MyTela(),
        '/registro': (context) => InfoOng(),
        '/login': (context) => MyLogin(),
        '/postagem': (context) => PostScreen(),
        '/SN': (context) => MySN(),
        '/CadUsuario': (context) => cliente(),
        '/CadOng': (context) => ong(),
        '/hong': (context) => HomeONG(),
        '/chat': (context) => TelaChat(),
      },
    );
  }
}
