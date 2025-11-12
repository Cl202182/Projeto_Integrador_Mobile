import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_projeto_integrador/components/bottom_nav_bar.dart';

class Contato extends StatefulWidget {
  const Contato({super.key});

  @override
  State<Contato> createState() => _ContatoState();
}

class _ContatoState extends State<Contato> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String? currentUserName;
  String? currentUserEmail;
  late DatabaseReference _chatsRef;

  @override
  void initState() {
    super.initState();
    _chatsRef = FirebaseDatabase.instance.ref().child('chats');
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      // Primeiro tenta buscar na collection 'users'
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          currentUserName = userData['nome'] ?? userData['name'] ?? 'Usuário';
          currentUserEmail = userData['email'] ?? '';
        });
      } else {
        // Se não encontrar em 'users', tenta em 'ongs'
        DocumentSnapshot ongDoc = await FirebaseFirestore.instance
            .collection('ongs')
            .doc(currentUserId)
            .get();

        if (ongDoc.exists) {
          final ongData = ongDoc.data() as Map<String, dynamic>;
          setState(() {
            currentUserName = ongData['nome'] ?? ongData['name'] ?? 'Usuário';
            currentUserEmail = ongData['email'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
      setState(() {
        currentUserName = 'Usuário';
        currentUserEmail = '';
      });
    }
  }

  // Função para extrair IDs de ONGs das conversas em tempo real
  List<String> _extractConversedOngIds(DatabaseEvent event) {
    Set<String> ongIds = {};

    if (event.snapshot.exists) {
      final chatsData = Map<String, dynamic>.from(event.snapshot.value as Map);

      for (String chatId in chatsData.keys) {
        // Verifica se o chatId contém o currentUserId
        if (chatId.contains(currentUserId) && chatId.contains('_')) {
          final parts = chatId.split('_');
          if (parts.length == 2) {
            // Encontra o outro participante
            final otherUserId = parts[0] == currentUserId ? parts[1] : parts[0];
            if (otherUserId != currentUserId) {
              // Verifica se realmente existem mensagens neste chat
              final chatData = chatsData[chatId];
              if (chatData != null && chatData['messages'] != null) {
                ongIds.add(otherUserId);
              }
            }
          }
        }
      }
    }

    print('IDs de ONGs encontrados em tempo real: $ongIds'); // Debug
    return ongIds.toList();
  }

  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchOngsPage(
          currentUserId: currentUserId,
          currentUserName: currentUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Conversas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header com usuário conectado
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 1, 37, 54),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(22.5),
                    ),
                    child: Center(
                      child: Text(
                        currentUserName != null && currentUserName!.isNotEmpty
                            ? currentUserName![0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conectado como:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentUserName ?? 'Carregando...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (currentUserEmail != null &&
                            currentUserEmail!.isNotEmpty)
                          Text(
                            currentUserEmail!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Botão de pesquisa estilizado
                  GestureDetector(
                    onTap: _openSearchPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pesquisar',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de conversas existentes em tempo real
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatsRef.onValue,
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar conversas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!chatSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 1, 37, 54),
                    ),
                  );
                }

                // Extrai IDs das ONGs com conversas
                final conversedOngIds =
                    _extractConversedOngIds(chatSnapshot.data!);

                if (conversedOngIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma conversa ainda',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque no ícone de pesquisa para encontrar ONGs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openSearchPage,
                          icon: const Icon(Icons.search),
                          label: const Text('Pesquisar ONGs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 1, 37, 54),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // StreamBuilder para buscar dados das ONGs
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ongs')
                      .where(FieldPath.documentId,
                          whereIn: conversedOngIds.isEmpty
                              ? ['dummy']
                              : conversedOngIds)
                      .snapshots(),
                  builder: (context, ongSnapshot) {
                    if (ongSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Erro ao carregar dados das ONGs',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!ongSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 1, 37, 54),
                        ),
                      );
                    }

                    final ongs = ongSnapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ongs.length,
                      itemBuilder: (context, index) {
                        final ongData =
                            ongs[index].data() as Map<String, dynamic>;
                        final ongId = ongs[index].id;
                        final ongName = ongData['nome'] ??
                            ongData['name'] ??
                            'ONG sem nome';
                        final ongEmail = ongData['email'] ?? '';
                        final ongDescription = ongData['descricao'] ??
                            ongData['description'] ??
                            '';
                        final areasAtuacao =
                            List<String>.from(ongData['areasAtuacao'] ?? []);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                String chatId =
                                    generateChatId(currentUserId, ongId);

                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: {
                                    'chatId': chatId,
                                    'userName': ongName,
                                    'userId': ongId,
                                    'currentUserId': currentUserId,
                                    'currentUserName': currentUserName,
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 1, 37, 54),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          ongName.isNotEmpty
                                              ? ongName[0].toUpperCase()
                                              : 'O',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Informações da ONG
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ongName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color.fromARGB(
                                                  255, 1, 37, 54),
                                            ),
                                          ),
                                          if (areasAtuacao.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: areasAtuacao
                                                  .take(2)
                                                  .map((area) => Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color
                                                                  .fromARGB(255,
                                                                  1, 37, 54)
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          area,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    1,
                                                                    37,
                                                                    54),
                                                          ),
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                            if (areasAtuacao.length > 2)
                                              Text(
                                                '+${areasAtuacao.length - 2} outras',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ] else if (ongDescription
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              ongDescription.length > 50
                                                  ? '${ongDescription.substring(0, 50)}...'
                                                  : ongDescription,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ] else if (ongEmail.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              ongEmail,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Ícone de seta
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        isOng: false,
      ),
    );
  }

  String generateChatId(String id1, String id2) {
    return (id1.hashCode <= id2.hashCode) ? '${id1}_$id2' : '${id2}_$id1';
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Página de pesquisa com filtros avançados
class SearchOngsPage extends StatefulWidget {
  final String currentUserId;
  final String? currentUserName;

  const SearchOngsPage({
    super.key,
    required this.currentUserId,
    this.currentUserName,
  });

  @override
  State<SearchOngsPage> createState() => _SearchOngsPageState();
}

class _SearchOngsPageState extends State<SearchOngsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  bool _showFilters = false;

  // Áreas de atuação disponíveis (mesmas do PerfilOng)
  final List<String> areasDisponiveis = [
    'Educação',
    'Saúde',
    'Meio Ambiente',
    'Assistência Social',
    'Cultura',
    'Esporte',
    'Direitos Humanos',
    'Animais',
    'Idosos',
    'Crianças e Adolescentes',
  ];

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
    });
  }

  bool _ongMatchesFilters(Map<String, dynamic> ongData) {
    if (_selectedFilters.isEmpty) return true;

    final ongAreas = List<String>.from(ongData['areasAtuacao'] ?? []);

    // Verifica se a ONG tem pelo menos uma área selecionada
    return _selectedFilters.any((filter) => ongAreas.contains(filter));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 37, 54),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pesquisar ONGs...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
        actions: [
          // Botão de filtros
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune, color: Colors.white),
                if (_selectedFilters.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_selectedFilters.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Painel de filtros
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 120 : 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtrar por área de atuação:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedFilters.isNotEmpty)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text(
                              'Limpar',
                              style: TextStyle(
                                color: Color.fromARGB(255, 1, 37, 54),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: areasDisponiveis.map((area) {
                          bool isSelected = _selectedFilters.contains(area);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                area,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color.fromARGB(255, 1, 37, 54),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) => _toggleFilter(area),
                              backgroundColor: Colors.grey[200],
                              selectedColor:
                                  const Color.fromARGB(255, 1, 37, 54),
                              checkmarkColor: Colors.white,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de resultados
          Expanded(
            child: _searchQuery.isEmpty && _selectedFilters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Digite para pesquisar ONGs',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use os filtros para buscar por área de atuação',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ongs')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erro ao carregar ONGs'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 1, 37, 54),
                          ),
                        );
                      }

                      // Filtra ONGs
                      final ongs = snapshot.data!.docs.where((doc) {
                        final ongData = doc.data() as Map<String, dynamic>;
                        final ongName =
                            ongData['nome'] ?? ongData['name'] ?? '';
                        final ongId = doc.id;

                        // Exclui o próprio usuário
                        if (ongId == widget.currentUserId) return false;

                        // Aplica filtro de pesquisa por nome
                        bool matchesSearch = _searchQuery.isEmpty ||
                            ongName.toLowerCase().contains(_searchQuery);

                        // Aplica filtros de áreas de atuação
                        bool matchesFilters = _ongMatchesFilters(ongData);

                        return matchesSearch && matchesFilters;
                      }).toList();

                      if (ongs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhuma ONG encontrada',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_selectedFilters.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tente ajustar os filtros',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ongs.length,
                        itemBuilder: (context, index) {
                          final ongData =
                              ongs[index].data() as Map<String, dynamic>;
                          final ongId = ongs[index].id;
                          final ongName = ongData['nome'] ??
                              ongData['name'] ??
                              'ONG sem nome';
                          final ongEmail = ongData['email'] ?? '';
                          final ongDescription = ongData['descricao'] ??
                              ongData['description'] ??
                              '';
                          final areasAtuacao =
                              List<String>.from(ongData['areasAtuacao'] ?? []);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  String chatId = _generateChatId(
                                      widget.currentUserId, ongId);

                                  Navigator.pop(
                                      context); // Fecha a tela de pesquisa
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'chatId': chatId,
                                      'userName': ongName,
                                      'userId': ongId,
                                      'currentUserId': widget.currentUserId,
                                      'currentUserName': widget.currentUserName,
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                  255, 1, 37, 54),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            child: Center(
                                              child: Text(
                                                ongName.isNotEmpty
                                                    ? ongName[0].toUpperCase()
                                                    : 'O',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ongName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color.fromARGB(
                                                        255, 1, 37, 54),
                                                  ),
                                                ),
                                                if (ongDescription
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    ongDescription.length > 80
                                                        ? '${ongDescription.substring(0, 80)}...'
                                                        : ongDescription,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ] else if (ongEmail
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    ongEmail,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      // Áreas de atuação
                                      if (areasAtuacao.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: areasAtuacao.map((area) {
                                              bool isHighlighted =
                                                  _selectedFilters
                                                      .contains(area);
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isHighlighted
                                                      ? const Color.fromARGB(
                                                              255, 1, 37, 54)
                                                          .withOpacity(0.2)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isHighlighted
                                                        ? const Color.fromARGB(
                                                            255, 1, 37, 54)
                                                        : Colors.grey[300]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  area,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isHighlighted
                                                        ? const Color.fromARGB(
                                                            255, 1, 37, 54)
                                                        : Colors.grey[700],
                                                    fontWeight: isHighlighted
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        isOng: false,
      ),
    );
  }

  String _generateChatId(String id1, String id2) {
    return (id1.hashCode <= id2.hashCode) ? '${id1}_$id2' : '${id2}_$id1';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
