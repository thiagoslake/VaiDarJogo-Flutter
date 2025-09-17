import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';
import 'game_search_screen.dart';
import 'admin_panel_screen.dart';
import 'participation_requests_screen.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _userGames = [];
  List<Map<String, dynamic>> _adminGames = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // Primeiro, buscar o player_id do usuário
      final playerResponse = await SupabaseConfig.client
          .from('players')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      List<Map<String, dynamic>> userGames = [];

      if (playerResponse != null) {
        // Buscar jogos que o usuário participa
        final userGamesResponse = await SupabaseConfig.client
            .from('game_players')
            .select('''
              games:game_id (
                id,
                organization_name,
                location,
                address,
                status,
                created_at,
                players_per_team,
                substitutes_per_team,
                number_of_teams,
                start_time,
                end_time,
                game_date,
                day_of_week,
                frequency
              )
            ''')
            .eq('player_id', playerResponse['id'])
            .eq('status', 'active')
            .eq('games.status', 'active')
            .order('games(created_at)', ascending: false);

        userGames = List<Map<String, dynamic>>.from(userGamesResponse);
      }

      // Buscar jogos que o usuário administra
      final adminGamesResponse = await SupabaseConfig.client
          .from('games')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      setState(() {
        _userGames = userGames
            .map((item) => item['games'] as Map<String, dynamic>?)
            .where((game) => game != null)
            .cast<Map<String, dynamic>>()
            .toList();

        _adminGames = List<Map<String, dynamic>>.from(adminGamesResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = _adminGames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Jogos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Botão de administração (apenas para admins)
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
              tooltip: 'Painel de Administração',
            ),
          // Menu do usuário
          if (currentUser != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  currentUser.name.isNotEmpty
                      ? currentUser.name[0].toUpperCase()
                      : 'U',
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
                        currentUser.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
              : _buildDashboard(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GameSearchScreen(),
            ),
          );
        },
        icon: const Icon(Icons.search),
        label: const Text('Buscar Jogos'),
        backgroundColor: Colors.green,
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
                'Erro ao carregar dados',
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
                onPressed: _loadUserData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho de boas-vindas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao VaiDarJogo!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie seus jogos e participe de novos',
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

          // Jogos que participa
          _buildSection(
            title: '🎮 Jogos que Participo',
            subtitle: 'Jogos onde você está cadastrado como jogador',
            games: _userGames,
            emptyMessage: 'Você ainda não participa de nenhum jogo',
            emptyAction: 'Buscar Jogos',
            onEmptyAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GameSearchScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Jogos que administra (apenas para admins)
          if (_adminGames.isNotEmpty)
            _buildSection(
              title: '⚙️ Jogos que Administro',
              subtitle: 'Jogos onde você é administrador',
              games: _adminGames,
              emptyMessage: 'Você não administra nenhum jogo',
              emptyAction: 'Criar Jogo',
              onEmptyAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
              isAdmin: true,
            ),

          const SizedBox(height: 16),

          // Solicitações pendentes
          _buildParticipationRequests(),

          const SizedBox(height: 80), // Espaço para o FAB
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> games,
    required String emptyMessage,
    required String emptyAction,
    required VoidCallback onEmptyAction,
    bool isAdmin = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (games.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${games.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (games.isEmpty)
              _buildEmptyState(emptyMessage, emptyAction, onEmptyAction)
            else
              _buildGamesList(games, isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      String message, String actionText, VoidCallback onAction) {
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
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionText),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(List<Map<String, dynamic>> games, bool isAdmin) {
    return Column(
      children:
          games.take(3).map((game) => _buildGameCard(game, isAdmin)).toList()
            ..addAll([
              if (games.length > 3) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // TODO: Navegar para tela de lista completa
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento'),
                      ),
                    );
                  },
                  child: Text('Ver todos os ${games.length} jogos'),
                ),
              ],
            ]),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? Colors.blue : Colors.green,
          child: Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.sports_soccer,
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
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          if (isAdmin) {
            // Navegar para painel de administração
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminPanelScreen(),
              ),
            );
          } else {
            // Navegar para detalhes do jogo
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Detalhes do jogo em desenvolvimento'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildParticipationRequests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Solicitações de Participação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Suas solicitações pendentes de aprovação',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ParticipationRequestsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.pending_actions),
              label: const Text('Ver Solicitações'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
