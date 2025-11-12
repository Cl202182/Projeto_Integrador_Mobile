import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isOng;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.isOng,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0: // Início
        if (isOng) {
          Navigator.pushNamedAndRemoveUntil(context, '/hong', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/huser', (route) => false);
        }
        break;
      case 1: // Chat/Atendimentos
        if (isOng) {
          Navigator.pushNamed(context, '/contatoOng');
        } else {
          Navigator.pushNamed(context, '/contatoUser');
        }
        break;
      case 2: // Perfil
        if (isOng) {
          Navigator.pushNamed(context, '/visong');
        } else {
          Navigator.pushNamed(context, '/perfilUser');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(255, 1, 37, 54),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat),
          label: isOng ? 'Atendimentos' : 'Chat',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
