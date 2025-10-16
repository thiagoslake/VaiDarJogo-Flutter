import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';
import 'game_search_screen.dart';
import 'admin_panel_screen.dart';
import 'participation_requests_screen.dart';
import 'game_details_screen.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import 'create_game_screen.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Map<String, dynamic>> _userGames = [];
  List<Map<String, dynamic>> _adminGames = [];
  String? _error;
  bool _isAdmin = false;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _shouldRefresh()) {
      print('🔄 App voltou ao foco - Atualizando listagem de jogos...');
      _loadUserData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Remover chamadas excessivas de didChangeDependencies
    // O refresh automático já é controlado pelo didChangeAppLifecycleState
    // e pelo método público refreshGamesList()
    print('🔍 didChangeDependencies chamado - não fazendo refresh automático');
  }

  /// Verificar se deve atualizar a listagem (evita atualizações muito frequentes)
  bool _shouldRefresh() {
    if (_lastRefresh == null) {
      print('🔍 _shouldRefresh: primeira vez, permitindo refresh');
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(_lastRefresh!);

    print(
        '🔍 _shouldRefresh: última atualização há ${difference.inSeconds}s, permitindo: ${difference.inSeconds > 2}');

    // Só atualiza se passou mais de 2 segundos desde a última atualização
    return difference.inSeconds > 2;
  }

  /// Método público para atualizar a listagem de jogos
  Future<void> refreshGamesList() async {
    print('🔄 Refresh manual da listagem de jogos...');
    await _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Atualizar timestamp da última atualização
      _lastRefresh = DateTime.now();

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'Usuário não autenticado';
        });
        return;
      }

      // Primeiro, buscar o player_id do usuário
      final playerResponse = await SupabaseConfig.client
          .from('players')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (playerResponse == null) {
        setState(() {
          _isLoading = false;
          _error = 'Player não encontrado';
        });
        return;
      }

      final playerId = playerResponse['id'];

      // Buscar jogos onde o usuário participa
      final userGamesResponse =
          await SupabaseConfig.client.from('game_players').select('''
            id,
            game_id,
            status,
            joined_at,
            games:game_id(
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
              frequency,
              price_config
            )
          ''').eq('player_id', playerId).order('joined_at', ascending: false);

      // Buscar jogos onde o usuário é administrador
      print(
          '🔍 Debug - Buscando jogos administrados para user_id: ${currentUser.id}');

      // Primeiro, buscar jogos onde o usuário é administrador via game_players
      final adminGamesResponse = await SupabaseConfig.client
          .from('game_players')
          .select('''
            games:game_id(
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
              frequency,
              price_config
            )
          ''')
          .eq('player_id', playerId)
          .eq('is_admin', true)
          .eq('status', 'active')
          .order('joined_at', ascending: false);

      print(
          '🔍 Debug - Resposta da query de jogos administrados: $adminGamesResponse');

      // Processar jogos que o usuário participa
      final userGamesList = (userGamesResponse as List)
          .map((item) => item['games'] as Map<String, dynamic>)
          .toList();

      // Processar jogos que o usuário administra
      final adminGamesList = (adminGamesResponse as List)
          .map((item) => item['games'] as Map<String, dynamic>)
          .toList();

      // Combinar jogos, evitando duplicatas
      final Map<String, Map<String, dynamic>> allGamesMap = {};

      // Adicionar jogos que o usuário participa
      for (var game in userGamesList) {
        allGamesMap[game['id']] = {
          ...game,
          'is_admin': false, // Marcar como não administrador
        };
      }

      // Adicionar jogos que o usuário administra (sobrescreve se já existir)
      for (var game in adminGamesList) {
        allGamesMap[game['id']] = {
          ...game,
          'is_admin': true, // Marcar como administrador
        };
      }

      // Calcular número de jogadores e próxima sessão para cada jogo
      for (var gameId in allGamesMap.keys) {
        try {
          // Buscar número de jogadores registrados no jogo
          final playersCountResponse = await SupabaseConfig.client
              .from('game_players')
              .select('id')
              .eq('game_id', gameId)
              .inFilter('status', ['active', 'confirmed']);

          final currentPlayers = playersCountResponse.length;

          // Buscar próxima sessão do jogo (a partir de hoje)
          final today = DateTime.now();
          final todayString =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

          final nextSessionResponse = await SupabaseConfig.client
              .from('game_sessions')
              .select('session_date, start_time, end_time')
              .eq('game_id', gameId)
              .gte('session_date', todayString)
              .order('session_date', ascending: true)
              .limit(1);

          String? nextSessionDate;
          String? nextSessionStartTime;
          String? nextSessionEndTime;

          if (nextSessionResponse.isNotEmpty) {
            final session = nextSessionResponse.first;
            nextSessionDate = session['session_date'];
            nextSessionStartTime = session['start_time'];
            nextSessionEndTime = session['end_time'];
          }

          // Atualizar dados do jogo
          allGamesMap[gameId] = {
            ...allGamesMap[gameId]!,
            'current_players': currentPlayers,
            'next_session_date': nextSessionDate,
            'next_session_start_time': nextSessionStartTime,
            'next_session_end_time': nextSessionEndTime,
          };

          print(
              '🔍 DEBUG - Jogo ${allGamesMap[gameId]!['organization_name']}: $currentPlayers jogadores, próxima sessão: ${nextSessionDate ?? "N/A"} (buscando a partir de $todayString)');
        } catch (e) {
          print('⚠️ Erro ao calcular dados para jogo $gameId: $e');
          // Em caso de erro, usar valores padrão
          allGamesMap[gameId] = {
            ...allGamesMap[gameId]!,
            'current_players': 0,
            'next_session_date': null,
            'next_session_start_time': null,
            'next_session_end_time': null,
          };
        }
      }

      setState(() {
        _userGames = allGamesMap.values.toList();
        _adminGames = adminGamesList;
        _isAdmin = _adminGames.isNotEmpty; // Definir status de administrador
        _isLoading = false;
      });

      // Debug: verificar se há jogos administrados
      print(
          '🔍 Debug - Jogos administrados encontrados: ${_adminGames.length}');
      for (var game in _adminGames) {
        print(
            '🎮 Jogo administrado: ${game['organization_name']} (ID: ${game['id']})');
      }

      // Debug: verificar lista combinada
      print(
          '🔍 Debug - Total de jogos na lista combinada: ${_userGames.length}');
      for (var game in _userGames) {
        final isAdmin = game['is_admin'] == true;
        print(
            '🎮 Jogo: ${game['organization_name']} (ID: ${game['id']}) - Admin: $isAdmin');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erro ao carregar dados: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    // Usar a variável _isAdmin definida no carregamento de dados
    final isAdmin = !_isLoading && _isAdmin;

    // Debug: verificar status de administrador
    print(
        '🔍 Debug - isAdmin: $isAdmin, _isAdmin: $_isAdmin, _adminGames.length: ${_adminGames.length}, _isLoading: $_isLoading');
    print('🔍 Debug - currentUser.id: ${currentUser?.id}');
    if (_adminGames.isNotEmpty) {
      print('🔍 Debug - Primeiro jogo admin: ${_adminGames.first}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Jogos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Botão de atualizar
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar lista de jogos',
          ),
          // Menu do usuário
          if (currentUser != null)
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.green,
                backgroundImage: currentUser.profileImageUrl != null
                    ? NetworkImage(currentUser.profileImageUrl!)
                    : null,
                child: currentUser.profileImageUrl == null
                    ? Text(
                        currentUser.name.isNotEmpty
                            ? currentUser.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  );
                } else if (value == 'requests') {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ParticipationRequestsScreen(),
                    ),
                  );

                  // Se houve mudanças nas solicitações, atualizar a lista
                  if (result != null) {
                    print('🔄 Retorno das solicitações - Atualizando lista...');
                    await _loadUserData();
                  }
                } else if (value == 'admin_games') {
                  print('🔍 Debug - Navegando para AdminPanelScreen');
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );

                  // Se houve mudanças no painel admin, atualizar a lista
                  if (result != null) {
                    print('🔄 Retorno do painel admin - Atualizando lista...');
                    await _loadUserData();
                  }
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
                  value: 'requests',
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Solicitações'),
                    ],
                  ),
                ),
                if (isAdmin)
                  const PopupMenuItem(
                    value: 'admin_games',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Jogos que Administro'),
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
    );
  }

  Widget _buildErrorState() {
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
            'Erro ao carregar dados',
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
            onPressed: _loadUserData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final currentUser = ref.watch(currentUserProvider);

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto do perfil centralizada
            if (currentUser != null) ...[
              Center(
                child: _buildProfilePhoto(currentUser),
              ),
              const SizedBox(height: 20),
            ],

            // Jogos que participa
            _buildSection(
              title: '🎮 Jogos que Participo',
              subtitle: 'Jogos onde você está cadastrado como jogador',
              games: _userGames,
              emptyMessage: 'Você ainda não participa de nenhum jogo',
              emptyAction: 'Buscar Jogos',
              onEmptyAction: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameSearchScreen(),
                  ),
                );

                // Se o usuário se inscreveu em algum jogo, atualizar a lista
                if (result != null) {
                  print('🔄 Retorno da busca de jogos - Atualizando lista...');
                  await _loadUserData();
                }
              },
            ),

            const SizedBox(height: 20), // Espaço final
          ],
        ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com título e botão de criar jogo
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Botão de criar jogo
            IconButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateGameScreen(),
                  ),
                );

                if (!mounted) return;

                // Se um jogo foi criado, atualizar a tela
                if (result != null) {
                  print('🎮 Jogo criado, atualizando lista de jogos...');
                  await _loadUserData();
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Criar Novo Jogo',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (games.isEmpty)
          _buildEmptyState(emptyMessage, emptyAction, onEmptyAction)
        else
          _buildGamesList(games),
      ],
    );
  }

  Widget _buildEmptyState(
      String message, String actionText, VoidCallback onAction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.sports_soccer_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.search),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList(List<Map<String, dynamic>> games) {
    return RefreshIndicator(
      onRefresh: () async {
        print('🔄 Atualizando listagem via pull-to-refresh...');
        await _loadUserData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: games.map((game) => _buildGameCard(game)).toList(),
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final isAdmin = game['is_admin'] == true;
    final gameStatus = game['status'] ?? 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          // Navegar para detalhes do jogo
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GameDetailsScreen(
                gameId: game['id'],
                gameName: game['organization_name'] ?? 'Jogo',
              ),
            ),
          );

          // Se houve mudanças no jogo, atualizar a lista
          if (result != null) {
            print('🔄 Retorno da jornada - Atualizando lista de jogos...');
            await _loadUserData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game['organization_name'] ?? 'Jogo sem nome',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Indicador de status do jogo
                  _buildGameStatusIndicator(gameStatus),
                  const SizedBox(width: 8),
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Mostrar informações adicionais do jogo se disponíveis
              if (game['address'] != null &&
                  game['address'].toString().isNotEmpty)
                Text(
                  '📍 ${game['address']?.toString() ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['location']?.toString() ?? 'Local não informado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['next_session_date'] != null
                          ? _formatDate(
                              DateTime.parse(game['next_session_date']))
                          : 'Próxima sessão não agendada',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['next_session_start_time'] != null &&
                              game['next_session_end_time'] != null
                          ? '${game['next_session_start_time']} - ${game['next_session_end_time']}'
                          : 'Horário não definido',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${game['current_players'] ?? 0} jogadores',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameStatusIndicator(String status) {
    switch (status) {
      case 'active':
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_filled,
                size: 12,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'ATIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'paused':
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_filled,
                size: 12,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'PAUSADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'deleted':
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_forever,
                size: 12,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'DELETADO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline,
                size: 12,
                color: Colors.white,
              ),
              SizedBox(width: 4),
              Text(
                'DESCONHECIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildProfilePhoto(currentUser) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: currentUser.profileImageUrl != null
            ? Image.network(
                currentUser.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 60,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  color: Colors.grey[400],
                  size: 60,
                ),
              ),
      ),
    );
  }
}
