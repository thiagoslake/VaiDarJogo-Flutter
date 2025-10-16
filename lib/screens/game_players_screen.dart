import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../models/game_player_model.dart';
import 'complete_player_profile_screen.dart';
import 'select_user_screen.dart';

class GamePlayersScreen extends ConsumerStatefulWidget {
  const GamePlayersScreen({super.key});

  @override
  ConsumerState<GamePlayersScreen> createState() => _GamePlayersScreenState();
}

class _GamePlayersScreenState extends ConsumerState<GamePlayersScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selectedGame = ref.read(selectedGameProvider);
      final currentUser = ref.read(currentUserProvider);

      if (selectedGame == null) {
        setState(() {
          _error = 'Nenhum jogo selecionado';
          _isLoading = false;
        });
        return;
      }

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
            gameId: selectedGame.id,
            playerId: playerResponse['id'],
          );
        } else {
          _isAdmin = false;
        }
      } else {
        _isAdmin = false;
      }

      // Buscar todos os jogadores do jogo
      print(
          '🔍 DEBUG - GamePlayersScreen: Buscando jogadores do jogo ${selectedGame.id}');
      final gamePlayers = await PlayerService.getGamePlayers(
        gameId: selectedGame.id,
      );

      print(
          '🔍 DEBUG - GamePlayersScreen: ${gamePlayers.length} jogadores encontrados');

      if (gamePlayers.isEmpty) {
        print('🔍 DEBUG - GamePlayersScreen: Nenhum jogador encontrado');
        setState(() {
          _players = [];
          _isLoading = false;
        });
        return;
      }

      // Buscar dados dos jogadores com imagem de perfil
      final playerIds = gamePlayers.map((gp) => gp.playerId).toList();
      print('🔍 DEBUG - GamePlayersScreen: Player IDs: $playerIds');

      final response = await SupabaseConfig.client.from('players').select('''
            id,
            name,
            phone_number,
            birth_date,
            primary_position,
            secondary_position,
            preferred_foot,
            status,
            created_at,
            user_id,
            users:user_id(profile_image_url)
          ''').inFilter('id', playerIds).order('name', ascending: true);

      print(
          '🔍 DEBUG - GamePlayersScreen: Response dos players: ${response.length} registros');

      // Combinar dados dos jogadores com informações do relacionamento
      final playersWithGameInfo = response.map<Map<String, dynamic>>((player) {
        final gamePlayer = gamePlayers.firstWhere(
          (gp) => gp.playerId == player['id'],
        );

        // Extrair URL da imagem de perfil do usuário
        final userData = player['users'] as Map<String, dynamic>?;
        final profileImageUrl = userData?['profile_image_url'] as String?;

        // Verificar se o jogador é administrador do jogo
        final isPlayerAdmin = gamePlayer.isAdmin;

        return {
          ...player,
          'game_player_id': gamePlayer.id,
          'player_type': gamePlayer.playerType,
          'joined_at': gamePlayer.joinedAt.toIso8601String(),
          'status': gamePlayer.status,
          'profile_image_url': profileImageUrl,
          'is_admin': isPlayerAdmin,
        };
      }).toList();

      print(
          '🔍 DEBUG - GamePlayersScreen: Players com info do jogo: ${playersWithGameInfo.length}');
      print(
          '🔍 DEBUG - GamePlayersScreen: Primeiro player: ${playersWithGameInfo.isNotEmpty ? playersWithGameInfo.first['name'] : 'Nenhum'}');

      setState(() {
        _players = playersWithGameInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar jogadores: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePlayerType(String gamePlayerId, String newType) async {
    try {
      // Verificar se está mudando de avulso para mensalista
      final player =
          _players.firstWhere((p) => p['game_player_id'] == gamePlayerId);
      final currentType = player['player_type'];

      if (currentType == 'casual' && newType == 'monthly') {
        print(
            '🔄 Alterando jogador ${player['name']} de avulso para mensalista');

        // Verificar se o jogador já tem cadastro completo
        final hasCompleteProfile =
            await PlayerService.hasCompleteProfile(player['id']);

        if (hasCompleteProfile) {
          print(
              '✅ Jogador ${player['name']} já possui cadastro completo, alterando tipo diretamente');

          // Jogador já tem cadastro completo, alterar tipo diretamente
          await PlayerService.updatePlayerTypeInGame(
            gamePlayerId: gamePlayerId,
            playerType: newType,
          );

          // Recarregar dados
          await _loadData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${player['name']} alterado para Mensalista com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return;
        } else {
          print(
              '⚠️ Jogador ${player['name']} não possui cadastro completo, solicitando complemento');

          // Jogador não tem cadastro completo, solicitar complemento
          if (!mounted) return;
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CompletePlayerProfileScreen(
                playerId: player['id'],
                playerName: player['name'],
              ),
            ),
          );

          if (!mounted) return;

          // Se o usuário cancelou, não atualizar o tipo
          if (result != true) {
            print('❌ Usuário cancelou o complemento do cadastro');
            return;
          }
        }
      }

      // Atualizar tipo do jogador (para casos que não são casual -> monthly)
      await PlayerService.updatePlayerTypeInGame(
        gamePlayerId: gamePlayerId,
        playerType: newType,
      );

      // Recarregar dados
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tipo do jogador alterado para ${newType == 'monthly' ? 'Mensalista' : 'Avulso'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao alterar tipo do jogador: $e');
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

  Future<void> _addPlayerToGame() async {
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SelectUserScreen(),
        ),
      );

      if (!mounted) return;

      // Se o usuário foi adicionado com sucesso, recarregar dados
      if (result == true) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Usuário adicionado ao jogo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao adicionar usuário: $e');
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

  Future<void> _removePlayerFromGame(Map<String, dynamic> player) async {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) return;

    // Verificar se o jogador é administrador do jogo
    try {
      final isAdmin = await PlayerService.isPlayerGameAdmin(
        gameId: selectedGame.id,
        playerId: player['id'],
      );

      if (isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Não é possível remover o administrador do jogo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('❌ Erro ao verificar se jogador é administrador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao verificar permissões: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo de confirmação
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Jogador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja remover ${player['name']} do jogo?'),
            const SizedBox(height: 8),
            const Text(
              'O jogador será removido do jogo, mas seus dados pessoais serão preservados.',
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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      print(
          '🗑️ Removendo jogador ${player['name']} do jogo ${selectedGame.organizationName}');

      final success = await PlayerService.removePlayerFromGame(
        gameId: selectedGame.id,
        playerId: player['id'],
      );

      if (success) {
        // Recarregar dados
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ ${player['name']} removido do jogo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Falha ao remover jogador do jogo');
      }
    } catch (e) {
      print('❌ Erro ao remover jogador: $e');
      if (mounted) {
        String errorMessage = 'Erro ao remover jogador';

        // Tratar erros específicos
        if (e.toString().contains('administrador')) {
          errorMessage = 'Não é possível remover o administrador do jogo';
        } else if (e.toString().contains('permissão')) {
          errorMessage = 'Você não tem permissão para esta ação';
        } else {
          errorMessage = 'Erro ao remover jogador: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promoteToAdmin(Map<String, dynamic> player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promover a Administrador'),
        content: Text(
            'Tem certeza que deseja promover ${player['name']} a administrador do jogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Promover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      await PlayerService.promotePlayerToAdmin(
        gameId: selectedGame.id,
        playerId: player['id'],
      );

      // Recarregar dados
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${player['name']} promovido a administrador com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao promover jogador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao promover jogador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _demoteFromAdmin(Map<String, dynamic> player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Privilégios de Administrador'),
        content: Text(
            'Tem certeza que deseja remover os privilégios de administrador de ${player['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      await PlayerService.demotePlayerFromAdmin(
        gameId: selectedGame.id,
        playerId: player['id'],
      );

      // Recarregar dados
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Privilégios de administrador removidos de ${player['name']} com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao remover privilégios de administrador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover privilégios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAdminManagementDialog() async {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) return;

    try {
      // Buscar todos os administradores do jogo
      final admins = await PlayerService.getGameAdmins(gameId: selectedGame.id);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gerenciar Administradores'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Administradores atuais do jogo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (admins.isEmpty)
                  const Text(
                    'Nenhum administrador encontrado',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...admins.map((admin) => FutureBuilder<String>(
                        future: _getPlayerName(admin.playerId),
                        builder: (context, snapshot) {
                          final playerName =
                              snapshot.data ?? 'Nome não disponível';
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.admin_panel_settings,
                                  color: Colors.white),
                            ),
                            title: Text(playerName),
                            subtitle: Text(
                                'Administrador desde ${_formatDate(admin.joinedAt)}'),
                            trailing: admins.length > 1
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _demoteFromAdminDialog(admin),
                                    tooltip: 'Remover privilégios',
                                  )
                                : null,
                          );
                        },
                      )),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Para adicionar novos administradores, use os botões de ação na lista de jogadores.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar administradores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _demoteFromAdminDialog(GamePlayer admin) async {
    final playerName = await _getPlayerName(admin.playerId);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Privilégios de Administrador'),
        content: Text(
            'Tem certeza que deseja remover os privilégios de administrador de $playerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final selectedGame = ref.read(selectedGameProvider);
        if (selectedGame == null) return;

        await PlayerService.demotePlayerFromAdmin(
          gameId: selectedGame.id,
          playerId: admin.playerId,
        );

        // Recarregar dados
        await _loadData();

        if (mounted) {
          Navigator.of(context).pop(); // Fechar diálogo de administradores
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Privilégios de administrador removidos de $playerName com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover privilégios: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String> _getPlayerName(String playerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('players')
          .select('name')
          .eq('id', playerId)
          .maybeSingle();

      return response?['name'] ?? 'Nome não disponível';
    } catch (e) {
      return 'Nome não disponível';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showPlayerDetailsDialog(Map<String, dynamic> player) {
    final playerType = player['player_type'] as String;
    final isMonthly = playerType == 'monthly';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isMonthly ? Colors.blue[100] : Colors.orange[100],
              backgroundImage: player['profile_image_url'] != null
                  ? NetworkImage(player['profile_image_url'])
                  : null,
              child: player['profile_image_url'] == null
                  ? Text(
                      (player['name'] ?? 'N')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isMonthly ? Colors.blue[700] : Colors.orange[700],
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player['name'] ?? 'Nome não informado',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações básicas
              _buildDetailRow(
                  '📞', 'Telefone', player['phone_number'] ?? 'N/A'),

              if (player['birth_date'] != null)
                _buildDetailRow(
                    '🎂',
                    'Data de Nascimento',
                    _formatBirthDateWithAge(
                        DateTime.parse(player['birth_date']))),

              if (player['primary_position'] != null)
                _buildDetailRow(
                    '⚽', 'Posição Principal', player['primary_position']),

              if (player['secondary_position'] != null &&
                  player['secondary_position'] != 'Nenhuma')
                _buildDetailRow(
                    '🔄', 'Posição Secundária', player['secondary_position']),

              if (player['preferred_foot'] != null)
                _buildDetailRow('🦶', 'Pé Preferido', player['preferred_foot']),

              _buildDetailRow('📅', 'Entrou no jogo em',
                  _formatDate(DateTime.parse(player['joined_at']))),

              const SizedBox(height: 16),

              // Seção de tipo do jogador
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isMonthly ? Icons.calendar_month : Icons.event,
                          size: 20,
                          color:
                              isMonthly ? Colors.blue[700] : Colors.orange[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tipo de Jogador',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMonthly
                                ? Colors.blue[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isMonthly ? 'Mensalista' : 'Avulso',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isMonthly
                                  ? Colors.blue[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_isAdmin) ...[
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showPlayerTypeDialog(player);
                            },
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            tooltip: 'Alterar tipo',
                          ),
                        ],
                      ],
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Toque no ícone de edição para alterar o tipo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showPlayerTypeDialog(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Tipo de Jogador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Jogador: ${player['name']}'),
            const SizedBox(height: 16),
            const Text('Selecione o novo tipo:'),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'monthly',
                  label: Text('Mensalista'),
                  tooltip: 'Jogador fixo mensal',
                ),
                ButtonSegment<String>(
                  value: 'casual',
                  label: Text('Avulso'),
                  tooltip: 'Jogador eventual',
                ),
              ],
              selected: {player['player_type']},
              onSelectionChanged: (Set<String> selection) {
                Navigator.pop(context);
                _updatePlayerType(player['game_player_id'], selection.first);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Jogadores - ${selectedGame?.organizationName ?? 'Jogo'}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _showAdminManagementDialog,
              tooltip: 'Gerenciar Administradores',
            ),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _addPlayerToGame,
              tooltip: 'Adicionar Usuário',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
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
              'Nenhum jogador encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este jogo ainda não possui jogadores cadastrados.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com informações
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jogadores do Jogo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${_players.length} jogador(es)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Modo Administrador',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lista de jogadores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              return _buildPlayerCard(player);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final playerType = player['player_type'] as String;
    final isMonthly = playerType == 'monthly';
    final isPlayerAdmin = player['is_admin'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () => _showPlayerDetailsDialog(player),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar do jogador
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isMonthly ? Colors.blue[100] : Colors.orange[100],
                backgroundImage: player['profile_image_url'] != null
                    ? NetworkImage(player['profile_image_url'])
                    : null,
                child: player['profile_image_url'] == null
                    ? Text(
                        (player['name'] ?? 'N')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isMonthly ? Colors.blue[700] : Colors.orange[700],
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Informações principais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'] ?? 'Nome não informado',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player['phone_number'] ?? 'Telefone não informado',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Controles do administrador
              if (_isAdmin) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Switch do tipo
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isMonthly,
                          onChanged: (value) {
                            _updatePlayerType(
                              player['game_player_id'],
                              value ? 'monthly' : 'casual',
                            );
                          },
                          activeThumbColor: Colors.blue,
                          inactiveThumbColor: Colors.orange,
                          inactiveTrackColor: Colors.orange[200],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMonthly ? 'Mensalista' : 'Avulso',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isMonthly
                                ? Colors.blue[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    // Botões de ação para administradores
                    if (_isAdmin) ...[
                      const SizedBox(width: 8),
                      if (!isPlayerAdmin) ...[
                        // Botão para promover a administrador
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings,
                              color: Colors.blue),
                          onPressed: () => _promoteToAdmin(player),
                          tooltip: 'Promover a Administrador',
                          iconSize: 20,
                        ),
                        // Botão para remover do jogo
                        IconButton(
                          icon: const Icon(Icons.person_remove,
                              color: Colors.red),
                          onPressed: () => _removePlayerFromGame(player),
                          tooltip: 'Remover do Jogo',
                          iconSize: 20,
                        ),
                      ] else ...[
                        // Botão para remover privilégios de administrador
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings_outlined,
                              color: Colors.orange),
                          onPressed: () => _demoteFromAdmin(player),
                          tooltip: 'Remover Privilégios de Administrador',
                          iconSize: 20,
                        ),
                        // Badge de administrador
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // Para não-administradores, apenas mostrar badge se for admin
                      if (isPlayerAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ] else ...[
                // Badge do tipo (para usuários comuns)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMonthly ? Colors.blue[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMonthly ? Icons.calendar_month : Icons.event,
                        size: 14,
                        color:
                            isMonthly ? Colors.blue[700] : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMonthly ? 'Mensalista' : 'Avulso',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isMonthly ? Colors.blue[700] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Verificar se o aniversário ainda não aconteceu este ano
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  String _formatBirthDateWithAge(DateTime birthDate) {
    final age = _calculateAge(birthDate);
    final formattedDate = _formatDate(birthDate);
    return '$formattedDate ($age anos)';
  }
}
