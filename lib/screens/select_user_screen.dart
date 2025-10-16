import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selected_game_provider.dart';
import '../services/user_service.dart';
import '../services/player_service.dart';
import '../models/user_model.dart';

class SelectUserScreen extends ConsumerStatefulWidget {
  const SelectUserScreen({super.key});

  @override
  ConsumerState<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends ConsumerState<SelectUserScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';
  bool _isAdmin = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) {
        setState(() {
          _error = 'Nenhum jogo selecionado';
          _isLoading = false;
        });
        return;
      }

      print(
          '🔍 Carregando jogadores disponíveis para o jogo: ${selectedGame.organizationName}');

      // Buscar jogadores disponíveis para o jogo
      final availableUsers =
          await UserService.getAvailableUsersForGame(selectedGame.id);

      setState(() {
        _users = availableUsers;
        _filteredUsers = availableUsers;
        _isLoading = false;
      });

      print('✅ ${availableUsers.length} jogadores disponíveis encontrados');
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar usuários: $e';
        _isLoading = false;
      });
      print('❌ Erro ao carregar usuários: $e');
    }
  }

  void _filterUsers(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      if (searchTerm.trim().isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _addUserToGame(User user) async {
    try {
      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      print(
          '🔄 Adicionando usuário ${user.name} ao jogo ${selectedGame.organizationName} como ${_isAdmin ? 'Administrador' : 'Jogador'}');

      // Verificar se o usuário já tem perfil de jogador
      final hasPlayerProfile = await PlayerService.hasPlayerProfile(user.id);

      String playerId;

      if (hasPlayerProfile) {
        // Usuário já tem perfil de jogador, buscar o ID
        final player = await PlayerService.getPlayerByUserId(user.id);
        if (player == null) {
          throw Exception('Erro ao buscar perfil de jogador');
        }
        playerId = player.id;
        print('✅ Usuário já possui perfil de jogador: ${player.name}');
      } else {
        // Usuário não tem perfil de jogador, criar um básico
        print('📝 Criando perfil de jogador básico para ${user.name}');

        final player = await PlayerService.createPlayer(
          userId: user.id,
          name: user.name,
          phoneNumber: user.phone ?? '00000000000',
        );

        if (player == null) {
          throw Exception('Erro ao criar perfil de jogador');
        }

        playerId = player.id;
        print('✅ Perfil de jogador criado: ${player.id}');
      }

      // Adicionar jogador ao jogo (padrão: mensalista)
      final gamePlayer = await PlayerService.addPlayerToGame(
        gameId: selectedGame.id,
        playerId: playerId,
        playerType: 'monthly',
        isAdmin: _isAdmin,
      );

      if (gamePlayer == null) {
        throw Exception('Erro ao adicionar jogador ao jogo');
      }

      print('✅ Jogador adicionado ao jogo com sucesso');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${user.name} adicionado ao jogo como ${_isAdmin ? 'Administrador' : 'Jogador'}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Retornar true para indicar sucesso
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Erro ao adicionar usuário ao jogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao adicionar usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Selecionar Jogador - ${selectedGame?.organizationName ?? 'Jogo'}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterUsers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _filterUsers,
                ),
                const SizedBox(height: 16),

                // Toggle para função de administrador
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Função no Jogo',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isAdmin ? 'Administrador' : 'Jogador',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAdmin,
                        onChanged: (value) {
                          setState(() {
                            _isAdmin = value;
                          });
                        },
                        activeThumbColor: Colors.blue,
                        activeTrackColor: Colors.blue[200],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de usuários
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar usuários',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchTerm.isNotEmpty
                  ? 'Nenhum jogador encontrado'
                  : 'Nenhum jogador disponível',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchTerm.isNotEmpty
                  ? 'Tente ajustar sua pesquisa'
                  : 'Todos os jogadores já estão neste jogo',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: user.phone != null && user.phone!.isNotEmpty
            ? Text(
                user.phone!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            : null,
        trailing: ElevatedButton(
          onPressed: () => _addUserToGame(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Adicionar'),
        ),
        isThreeLine: false,
      ),
    );
  }
}
