import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/game_status_provider.dart';
import '../providers/selected_game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../services/game_service.dart';
import 'upcoming_sessions_screen.dart';
import 'edit_game_screen.dart';
import 'notification_config_screen.dart';
import 'notification_status_screen.dart';
import 'game_players_screen.dart';

class GameDetailsScreen extends ConsumerStatefulWidget {
  final String gameId;
  final String gameName;

  const GameDetailsScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  ConsumerState<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends ConsumerState<GameDetailsScreen> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isAdmin = false;
  DateTime? _nextSessionDate;

  @override
  void initState() {
    super.initState();
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      // Verificar se o usuário é administrador do jogo
      final currentUser = ref.read(currentUserProvider);
      // Verificar se o jogo existe (não precisamos do user_id para a nova lógica)
      await SupabaseConfig.client
          .from('games')
          .select('id')
          .eq('id', widget.gameId)
          .single();

      // Verificar se o usuário é administrador do jogo
      if (currentUser != null) {
        // Buscar o player_id do usuário atual
        final playerResponse = await SupabaseConfig.client
            .from('players')
            .select('id')
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (playerResponse != null) {
          _isAdmin = await PlayerService.isPlayerGameAdmin(
            gameId: widget.gameId,
            playerId: playerResponse['id'],
          );
        } else {
          _isAdmin = false;
        }
      } else {
        _isAdmin = false;
      }

      // Carregar solicitações pendentes (apenas para administradores)
      if (_isAdmin) {
        final pendingRequestsResponse = await SupabaseConfig.client
            .from('game_players')
            .select('''
              id,
              player_id,
              status,
              joined_at,
              players:player_id(
                id,
                name,
                phone_number,
                user_id,
                users:user_id(
                  email
                )
              )
            ''')
            .eq('game_id', widget.gameId)
            .eq('status', 'pending')
            .order('joined_at', ascending: false);

        _pendingRequests = pendingRequestsResponse.cast<Map<String, dynamic>>();
      }

      // Carregar próxima sessão (para jogos que não são avulsos)
      await _loadNextSession();

      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameInfoAsync = ref.watch(gameInfoProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: gameInfoAsync.when(
        data: (game) => game != null
            ? _buildGameDetails(game)
            : const Center(child: Text('Jogo não encontrado')),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Erro: $error'),
        ),
      ),
    );
  }

  Widget _buildGameDetails(Game game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solicitações pendentes (apenas para administradores)
          if (_isAdmin) _buildPendingRequestsSection(),
          if (_isAdmin) const SizedBox(height: 24),

          // Opções de configuração (apenas para administradores)
          if (_isAdmin) _buildGameConfigurationOptions(game),
          if (_isAdmin) const SizedBox(height: 24),

          // Informações do jogo (para todos)
          _buildGameInfoSection(game),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _loadNextSession() async {
    try {
      // Buscar a próxima sessão do jogo
      final nextSessionResponse = await SupabaseConfig.client
          .from('game_sessions')
          .select('session_date')
          .eq('game_id', widget.gameId)
          .gte('session_date', DateTime.now().toIso8601String())
          .order('session_date', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextSessionResponse != null) {
        _nextSessionDate = DateTime.parse(nextSessionResponse['session_date']);
      } else {
        _nextSessionDate = null;
      }
    } catch (e) {
      print('❌ Erro ao carregar próxima sessão: $e');
      _nextSessionDate = null;
    }
  }

  Widget _buildPendingRequestsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '⏳ Solicitações Pendentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pendingRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange),
                  onPressed: _loadGameDetails,
                  tooltip: 'Atualizar solicitações',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pendingRequests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nenhuma solicitação pendente',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Todas as solicitações foram processadas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingRequests.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final request = _pendingRequests[index];
                  final player = request['players'] as Map<String, dynamic>?;
                  final playerName = player?['name'] ?? 'Jogador desconhecido';
                  final phoneNumber = player?['phone_number'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        playerName.isNotEmpty
                            ? playerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(playerName),
                    subtitle: Text(phoneNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () =>
                              _handleRequest(request['id'], 'confirmed'),
                          tooltip: 'Aprovar',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              _handleRequest(request['id'], 'declined'),
                          tooltip: 'Recusar',
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

  Widget _buildGameConfigurationOptions(Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Opções de Configuração',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de opções de configuração
            Column(
              children: [
                _buildConfigOption(
                  icon: Icons.event,
                  title: 'Sessões do Jogo',
                  subtitle: 'Visualizar todas as sessões',
                  color: Colors.green,
                  onTap: () {
                    ref.read(selectedGameProvider.notifier).state = game;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UpcomingSessionsScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigOption(
                  icon: Icons.edit,
                  title: 'Editar Jogo',
                  subtitle: 'Modificar configurações',
                  color: Colors.orange,
                  onTap: () {
                    ref.read(selectedGameProvider.notifier).state = game;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditGameScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigOption(
                  icon: Icons.notifications,
                  title: 'Configurar Notificações',
                  subtitle: 'Definir alertas e lembretes',
                  color: Colors.purple,
                  onTap: () {
                    ref.read(selectedGameProvider.notifier).state = game;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationConfigScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigOption(
                  icon: Icons.info,
                  title: 'Status das Notificações',
                  subtitle: 'Ver histórico de envios',
                  color: Colors.teal,
                  onTap: () {
                    ref.read(selectedGameProvider.notifier).state = game;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationStatusScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigOption(
                  icon: Icons.people,
                  title: 'Gerenciar Jogadores',
                  subtitle: 'Ver e editar participantes',
                  color: Colors.indigo,
                  onTap: () {
                    ref.read(selectedGameProvider.notifier).state = game;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GamePlayersScreen(),
                      ),
                    );
                  },
                ),
                // Opções baseadas no status do jogo
                _buildStatusBasedOptions(game),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói opções baseadas no status do jogo
  Widget _buildStatusBasedOptions(Game game) {
    print('🔍 Debug - Status do jogo: ${game.status}');

    switch (game.status) {
      case 'active':
        return Column(
          children: [
            _buildConfigOption(
              icon: Icons.pause_circle,
              title: 'Pausar Jogo',
              subtitle: 'Temporariamente desativar o jogo',
              color: Colors.amber,
              onTap: () => _pauseGame(game),
            ),
            _buildConfigOption(
              icon: Icons.delete_forever,
              title: 'Inativar Jogo',
              subtitle: 'Inativar jogo e remover sessões futuras',
              color: Colors.red,
              onTap: () => _deleteGame(game),
            ),
          ],
        );

      case 'paused':
        return Column(
          children: [
            _buildConfigOption(
              icon: Icons.play_circle,
              title: 'Despausar Jogo',
              subtitle: 'Reativar o jogo e próximas sessões',
              color: Colors.green,
              onTap: () => _resumeGame(game),
            ),
            _buildConfigOption(
              icon: Icons.delete_forever,
              title: 'Inativar Jogo',
              subtitle: 'Inativar jogo e remover sessões futuras',
              color: Colors.red,
              onTap: () => _deleteGame(game),
            ),
          ],
        );

      case 'deleted':
        return Column(
          children: [
            _buildConfigOption(
              icon: Icons.restore,
              title: 'Reativar Jogo',
              subtitle: 'Reativar jogo e recriar sessões futuras',
              color: Colors.green,
              onTap: () => _reactivateGame(game),
            ),
          ],
        );

      default:
        print('⚠️ Status desconhecido: ${game.status}');
        return Column(
          children: [
            _buildConfigOption(
              icon: Icons.help_outline,
              title: 'Status Desconhecido',
              subtitle: 'Status do jogo: ${game.status}',
              color: Colors.grey,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Status do jogo não reconhecido: ${game.status}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ],
        );
    }
  }

  Widget _buildConfigOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGameInfoSection(Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Jogo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('🏟️', 'Local', game.address ?? 'Não informado'),
            _buildInfoRow(
                '👥', 'Jogadores por time', '${game.playersPerTeam ?? 'N/A'}'),
            _buildInfoRow(
                '🔄', 'Substituições', '${game.substitutesPerTeam ?? 'N/A'}'),
            _buildInfoRow(
                '⚽', 'Número de times', '${game.numberOfTeams ?? 'N/A'}'),
            if (game.frequency == 'Jogo Avulso' && game.gameDate != null)
              _buildInfoRow('📅', 'Data do jogo',
                  _formatDate(DateTime.parse(game.gameDate!))),
            if (game.frequency != 'Jogo Avulso' && _nextSessionDate != null)
              _buildInfoRow(
                  '📅', 'Próxima sessão', _formatDate(_nextSessionDate!)),
            if (game.dayOfWeek != null)
              _buildInfoRow('📆', 'Dia da semana', game.dayOfWeek!),
            if (game.frequency != null)
              _buildInfoRow('🔄', 'Frequência', game.frequency!),
            if (game.frequency != 'Jogo Avulso' &&
                game.endDate != null &&
                game.endDate!.isNotEmpty)
              _buildInfoRow('📅', 'Data limite da recorrência',
                  _formatDate(DateTime.parse(game.endDate!))),
            if (game.priceConfig != null && game.priceConfig!.isNotEmpty)
              _buildInfoRow(
                  '💰', 'Preços', _formatPriceConfig(game.priceConfig!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPriceConfig(Map<String, dynamic> priceConfig) {
    final monthly = priceConfig['monthly']?.toString() ?? '0';
    final casual = priceConfig['casual']?.toString() ?? '0';
    return 'Mensal: R\$ $monthly | Avulso: R\$ $casual';
  }

  Future<void> _handleRequest(String requestId, String status) async {
    try {
      await SupabaseConfig.client
          .from('game_players')
          .update({'status': status}).eq('id', requestId);

      // Recarregar dados
      await _loadGameDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tipo do jogador alterado para ${status == 'confirmed' ? 'Mensalista' : 'Avulso'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar tipo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pauseGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pausar Jogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tem certeza que deseja pausar o jogo "${game.organizationName}"?'),
            const SizedBox(height: 8),
            const Text(
              'O jogo será temporariamente desativado e não aparecerá nas listagens ativas.',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pausar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GameService.pauseGame(gameId: game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Jogo "${game.organizationName}" pausado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidar provider para atualizar os dados
        ref.invalidate(gameInfoProvider(widget.gameId));

        // Voltar para a tela anterior com indicação de mudança
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao pausar jogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Despausar Jogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tem certeza que deseja despausar o jogo "${game.organizationName}"?'),
            const SizedBox(height: 8),
            const Text(
              'O jogo será reativado e todas as próximas sessões serão despausadas.',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '📅 Apenas sessões futuras serão reativadas.\nSessões passadas permanecerão pausadas.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Despausar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GameService.resumeGame(gameId: game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Jogo "${game.organizationName}" despausado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidar provider para atualizar os dados
        ref.invalidate(gameInfoProvider(widget.gameId));

        // Voltar para a tela anterior com indicação de mudança
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao despausar jogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inativar Jogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tem certeza que deseja inativar o jogo "${game.organizationName}"?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ ATENÇÃO: Esta ação não pode ser desfeita!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O que será feito:\n• Jogo será marcado como inativo\n• Sessões futuras serão removidas\n• Histórico de sessões passadas será preservado\n• Relacionamentos com jogadores serão inativados',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '📚 O histórico de sessões passadas será mantido para consulta.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GameService.deleteGame(gameId: game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Jogo "${game.organizationName}" inativado com sucesso! Histórico preservado.'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidar provider para atualizar os dados
        ref.invalidate(gameInfoProvider(widget.gameId));

        // Voltar para a tela anterior com indicação de mudança
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao inativar jogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reativar Jogo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Tem certeza que deseja reativar o jogo "${game.organizationName}"?'),
            const SizedBox(height: 8),
            const Text(
              '✅ Esta ação pode ser desfeita!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O que será feito:\n• Jogo será marcado como ativo\n• Sessões futuras serão recriadas\n• Relacionamentos com jogadores serão reativados\n• Histórico de sessões passadas será preservado',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '📚 O histórico de sessões passadas será mantido para consulta.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GameService.reactivateGame(gameId: game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Jogo "${game.organizationName}" reativado com sucesso! Sessões futuras recriadas.'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidar provider para atualizar os dados
        ref.invalidate(gameInfoProvider(widget.gameId));

        // Voltar para a tela anterior com indicação de mudança
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao reativar jogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
