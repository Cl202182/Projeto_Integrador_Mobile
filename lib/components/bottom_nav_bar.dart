import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../image_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isOng;
  final String? profileImageUrl;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.isOng,
    this.profileImageUrl,
  });

  String _getProxiedImageUrl(String originalUrl) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(originalUrl)}';
    }
    return originalUrl;
  }

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
        BottomNavigationBarItem(
          icon: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: currentIndex == 2 ? Colors.white : Colors.white70,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? SmartImage(
                      imageUrl: _getProxiedImageUrl(profileImageUrl!),
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      placeholder: Icon(
                        Icons.person,
                        color:
                            currentIndex == 2 ? Colors.white : Colors.white70,
                        size: 16,
                      ),
                      errorWidget: Icon(
                        Icons.person,
                        color:
                            currentIndex == 2 ? Colors.white : Colors.white70,
                        size: 16,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: currentIndex == 2 ? Colors.white : Colors.white70,
                      size: 16,
                    ),
            ),
          ),
          label: 'Perfil',
        ),
      ],
    );
  }
}
