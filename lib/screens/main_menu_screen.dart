import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_configuration_screen.dart';
import 'player_registration_screen.dart';
import 'create_game_screen.dart';
import 'admin_panel_screen.dart';
import '../providers/selected_game_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_status_provider.dart';
import '../config/supabase_config.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Tentar selecionar automaticamente o jogo ativo mais recente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectActiveGame();
    });
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        // Buscar o player_id do usuário atual
        final playerResponse = await SupabaseConfig.client
            .from('players')
            .select('id')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (playerResponse != null) {
          // Verificar se é administrador em algum jogo
          final adminGames = await SupabaseConfig.client
              .from('game_players')
              .select('id')
              .eq('player_id', playerResponse['id'])
              .eq('is_admin', true)
              .eq('status', 'active')
              .limit(1);

          setState(() {
            _isAdmin = adminGames.isNotEmpty;
          });
        } else {
          setState(() {
            _isAdmin = false;
          });
        }
      } catch (e) {
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  Future<void> _selectActiveGame() async {
    final activeGame = await ref.read(activeGameProvider.future);
    if (activeGame != null) {
      ref.read(selectedGameProvider.notifier).state = activeGame;
    }
  }

  Future<void> _toggleGameStatus(Game game) async {
    final newStatus = game.status == 'active' ? 'inactive' : 'active';
    final action = newStatus == 'active' ? 'ativar' : 'inativar';

    // Mostrar diálogo de confirmação
    final confirmed = await _showConfirmationDialog(
      title: 'Confirmar $action jogo',
      message:
          'Tem certeza que deseja $action o jogo "${game.organizationName}"?',
      confirmText: action.toUpperCase(),
      isDestructive: newStatus == 'inactive',
    );

    if (!confirmed) return;

    try {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Usar o provider para atualizar o status
      await ref
          .read(gameStatusProvider.notifier)
          .updateGameStatus(game.id, newStatus);

      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Atualizar providers relacionados
      ref.invalidate(gamesListProvider);
      ref.invalidate(activeGamesProvider);
      ref.invalidate(activeGameProvider);
      ref.invalidate(gameStatusProviderFuture(game.id));
      ref.invalidate(isGameActiveProvider(game.id));
      ref.invalidate(gameInfoProvider(game.id));

      // Mostrar mensagem de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Jogo ${action}do com sucesso!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver Status',
              textColor: Colors.white,
              onPressed: () {
                // Opcional: mostrar detalhes do status atualizado
                _showStatusUpdateDialog(game, newStatus);
              },
            ),
          ),
        );
      }

      // Se o jogo foi inativado e era o selecionado, limpar seleção
      if (newStatus == 'inactive' &&
          ref.read(selectedGameProvider)?.id == game.id) {
        ref.read(selectedGameProvider.notifier).state = null;
        // Tentar selecionar outro jogo ativo
        _selectActiveGame();
      }
    } catch (e) {
      // Fechar loading se ainda estiver aberto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao $action jogo: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () => _toggleGameStatus(game),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildConfigButton(Game game, String currentStatus) {
    final isActive = currentStatus == 'active';

    final button = OutlinedButton.icon(
      onPressed: isActive
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GameConfigurationScreen(),
                ),
              );
            }
          : null,
      icon: Icon(
        Icons.settings,
        size: 18,
        color: isActive ? Colors.blue : Colors.grey,
      ),
      label: Text(
        'Configurar',
        style: TextStyle(
          fontSize: 14,
          color: isActive ? Colors.blue : Colors.grey,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? Colors.blue : Colors.grey,
        side: BorderSide(
          color: isActive ? Colors.blue : Colors.grey,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: isActive ? null : Colors.grey.shade100,
      ),
    );

    // Adicionar tooltip quando o botão estiver desabilitado
    if (!isActive) {
      return Tooltip(
        message: 'Ative o jogo para poder configurá-lo',
        child: button,
      );
    }

    return button;
  }

  Widget _buildStatusButton(Game game, String currentStatus) {
    return Consumer(
      builder: (context, ref, child) {
        final gameStatusNotifier = ref.watch(gameStatusProvider);

        return gameStatusNotifier.when(
          data: (_) => ElevatedButton.icon(
            onPressed: () => _toggleGameStatus(game),
            icon: Icon(
              currentStatus == 'active' ? Icons.pause : Icons.play_arrow,
              size: 18,
            ),
            label: Text(
              currentStatus == 'active' ? 'Inativar' : 'Ativar',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  currentStatus == 'active' ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          loading: () => Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Atualizando...',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stack) => ElevatedButton.icon(
            onPressed: () => _toggleGameStatus(game),
            icon: Icon(
              currentStatus == 'active' ? Icons.pause : Icons.play_arrow,
              size: 18,
            ),
            label: Text(
              currentStatus == 'active' ? 'Inativar' : 'Ativar',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  currentStatus == 'active' ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      },
    );
  }

  void _showStatusUpdateDialog(Game game, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              newStatus == 'active' ? Icons.check_circle : Icons.pause_circle,
              color: newStatus == 'active' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Status Atualizado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jogo: ${game.organizationName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Local: ${game.location}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: newStatus == 'active' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    newStatus == 'active' ? '🟢 Ativo' : '⚫ Inativo',
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
              'Data da atualização: ${_formatDate(DateTime.now())}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);
    final gamesAsync = ref.watch(gamesListProvider);

    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VaiDarJogo App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          // Informações do usuário
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
                } else if (value == 'admin_games') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
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
                if (_isAdmin)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'VaiDarJogo App',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie seus jogos de futebol',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Seleção de Jogo
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎮 Selecionar Jogo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      gamesAsync.when(
                        data: (games) =>
                            _buildGameSelector(games, selectedGame),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade600),
                                const SizedBox(height: 8),
                                Text(
                                  'Erro ao carregar jogos: $error',
                                  style: TextStyle(color: Colors.red.shade600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () =>
                                      ref.refresh(gamesListProvider),
                                  child: const Text('Tentar Novamente'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mostrar botões apenas se um jogo estiver selecionado
            if (selectedGame != null) ...[
              _buildGameInfo(selectedGame),
              const SizedBox(height: 16),

              // Opção 1 - Cadastro de Jogador
              _buildMenuCard(
                context,
                title: '👤 Cadastro de Jogador',
                subtitle: 'Incluir e consultar jogadores',
                icon: Icons.person_add,
                color: Colors.orange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PlayerRegistrationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Informações adicionais
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ℹ️ Informações',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este aplicativo sincroniza com o bot WhatsApp do VaiDarJogo para gerenciar jogos de futebol.',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Mensagem quando nenhum jogo está selecionado
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Selecione um jogo para continuar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha um jogo da lista acima para acessar as funcionalidades de gerenciamento.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelector(List<Game> games, Game? selectedGame) {
    if (games.isEmpty) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.add_circle, color: Colors.blue.shade600),
              const SizedBox(height: 8),
              Text(
                'Nenhum jogo encontrado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Crie seu primeiro jogo para começar',
                style: TextStyle(color: Colors.blue.shade700),
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
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<Game>(
            isExpanded: true,
            initialValue: selectedGame,
            decoration: const InputDecoration(
              labelText: 'Escolha o jogo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports_soccer),
            ),
            items: games.map((Game game) {
              return DropdownMenuItem<Game>(
                value: game,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${game.organizationName} - ${game.location}',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            onChanged: (Game? newGame) {
              if (newGame != null) {
                ref.read(selectedGameProvider.notifier).state = newGame;
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateGameScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Criar Novo Jogo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfo(Game game) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Jogo Selecionado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const Spacer(),
                // Indicador de status em tempo real
                Consumer(
                  builder: (context, ref, child) {
                    final gameStatusAsync =
                        ref.watch(gameStatusProviderFuture(game.id));
                    return gameStatusAsync.when(
                      data: (status) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              status == 'active' ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status == 'active' ? '🟢 Ativo' : '⚫ Inativo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) =>
                          const Icon(Icons.error, size: 16, color: Colors.red),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              game.organizationName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${game.location}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (game.address != null) ...[
              const SizedBox(height: 2),
              Text(
                '🏠 ${game.address}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  'Criado em ${_formatDate(game.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Botões de ação reativos
            Consumer(
              builder: (context, ref, child) {
                final gameStatusAsync =
                    ref.watch(gameStatusProviderFuture(game.id));
                return gameStatusAsync.when(
                  data: (status) => Row(
                    children: [
                      Expanded(
                        child: _buildStatusButton(game, status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConfigButton(game, status),
                      ),
                    ],
                  ),
                  loading: () => Row(
                    children: [
                      Expanded(
                        child: _buildStatusButton(game, game.status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConfigButton(game, game.status),
                      ),
                    ],
                  ),
                  error: (error, stack) => Row(
                    children: [
                      Expanded(
                        child: _buildStatusButton(game, game.status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildConfigButton(game, game.status),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
