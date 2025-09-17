import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/selected_game_provider.dart';
import '../config/supabase_config.dart';
import 'main_menu_screen.dart';
import 'admin_requests_screen.dart';
import 'login_screen.dart';
import 'create_game_screen.dart';
import 'user_profile_screen.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _adminGames = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdminGames();
  }

  Future<void> _loadAdminGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // Buscar jogos que o usuário administra
      final response = await SupabaseConfig.client
          .from('games')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      setState(() {
        _adminGames = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectGame(Map<String, dynamic> game) async {
    // Converter para o modelo Game
    final gameModel = Game.fromMap(game);

    // Definir como jogo selecionado
    ref.read(selectedGameProvider.notifier).state = gameModel;

    // Navegar para o menu principal (que agora será o painel de admin)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainMenuScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Administração'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Botão para voltar ao dashboard do usuário
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: 'Voltar ao Dashboard',
          ),
          // Menu do usuário
          if (currentUser != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  currentUser.name.isNotEmpty
                      ? currentUser.name[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  final navigator = Navigator.of(context);
                  await ref.read(authStateProvider.notifier).signOut();
                  if (mounted) {
                    navigator.pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Administrador',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Meu Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sair'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildAdminPanel(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateGameScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Criar Novo Jogo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar jogos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAdminGames,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Painel de Administração',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie seus jogos e solicitações',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Solicitações pendentes
          _buildPendingRequests(),

          const SizedBox(height: 16),

          // Jogos administrados
          _buildAdminGames(),

          const SizedBox(height: 80), // Espaço para o FAB
        ],
      ),
    );
  }

  Widget _buildPendingRequests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Solicitações Pendentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Nova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aprove ou rejeite solicitações de participação',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminRequestsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.pending_actions),
                label: const Text('Gerenciar Solicitações'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminGames() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Meus Jogos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_adminGames.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_adminGames.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione um jogo para gerenciar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_adminGames.isEmpty) _buildEmptyGames() else _buildGamesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGames() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Você ainda não criou nenhum jogo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateGameScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar Primeiro Jogo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    return Column(
      children: _adminGames.map((game) => _buildGameCard(game)).toList(),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final isActive = game['status'] == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: const Icon(
            Icons.sports_soccer,
            color: Colors.white,
          ),
        ),
        title: Text(
          game['organization_name'] ?? 'Sem nome',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${game['location'] ?? 'Local não informado'}'),
            if (game['day_of_week'] != null) Text('📅 ${game['day_of_week']}'),
            if (game['start_time'] != null) Text('🕐 ${game['start_time']}'),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Ativo' : 'Inativo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () => _selectGame(game),
      ),
    );
  }
}
