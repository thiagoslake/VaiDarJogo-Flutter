import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/player_confirmation_service.dart';
import '../services/game_service.dart';
import '../providers/selected_game_provider.dart';
import '../constants/app_colors.dart';

class ManualPlayerConfirmationScreen extends ConsumerStatefulWidget {
  const ManualPlayerConfirmationScreen({super.key});

  @override
  ConsumerState<ManualPlayerConfirmationScreen> createState() =>
      _ManualPlayerConfirmationScreenState();
}

class _ManualPlayerConfirmationScreenState
    extends ConsumerState<ManualPlayerConfirmationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  List<Map<String, dynamic>> _playersWithConfirmations = [];
  Map<String, String> _confirmationNotes = {};

  @override
  void initState() {
    super.initState();
    _loadPlayersWithConfirmations();
  }

  Future<void> _loadPlayersWithConfirmations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) {
        setState(() {
          _error = 'Jogo não selecionado';
          _isLoading = false;
        });
        return;
      }

      // Verificar se o jogo está ativo
      final isGameActive =
          await GameService.isGameActive(gameId: selectedGame.id);
      if (!isGameActive) {
        setState(() {
          _error =
              'Jogo pausado ou inativado. Confirmação manual não disponível.';
          _isLoading = false;
        });
        return;
      }

      // Carregar jogadores com confirmações
      _playersWithConfirmations =
          await PlayerConfirmationService.getGameConfirmationsWithPlayerInfo(
              selectedGame.id);

      // Inicializar notas
      for (final player in _playersWithConfirmations) {
        final playerId = player['player_id'].toString();
        _confirmationNotes[playerId] = player['notes'] ?? '';
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar jogadores: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPlayer(String playerId, String playerName) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      // Verificar se o jogo ainda está ativo
      final isGameActive =
          await GameService.isGameActive(gameId: selectedGame.id);
      if (!isGameActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Jogo pausado ou inativado. Confirmação não permitida.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final notes = _confirmationNotes[playerId] ?? '';

      final confirmation =
          await PlayerConfirmationService.confirmPlayerPresence(
        gameId: selectedGame.id,
        playerId: playerId,
        notes: notes.isNotEmpty ? notes : null,
        confirmationMethod: 'manual',
      );

      if (confirmation != null) {
        // Atualizar lista local
        final index = _playersWithConfirmations.indexWhere(
          (p) => p['player_id'].toString() == playerId,
        );
        if (index != -1) {
          _playersWithConfirmations[index]['confirmation_type'] = 'confirmed';
          _playersWithConfirmations[index]['confirmed_at'] =
              DateTime.now().toIso8601String();
          _playersWithConfirmations[index]['confirmation_method'] = 'manual';
          _playersWithConfirmations[index]['notes'] = notes;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $playerName confirmou presença!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao confirmar presença'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _declinePlayer(String playerId, String playerName) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      // Verificar se o jogo ainda está ativo
      final isGameActive =
          await GameService.isGameActive(gameId: selectedGame.id);
      if (!isGameActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Jogo pausado ou inativado. Confirmação não permitida.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final notes = _confirmationNotes[playerId] ?? '';

      final confirmation =
          await PlayerConfirmationService.declinePlayerPresence(
        gameId: selectedGame.id,
        playerId: playerId,
        notes: notes.isNotEmpty ? notes : null,
        confirmationMethod: 'manual',
      );

      if (confirmation != null) {
        // Atualizar lista local
        final index = _playersWithConfirmations.indexWhere(
          (p) => p['player_id'].toString() == playerId,
        );
        if (index != -1) {
          _playersWithConfirmations[index]['confirmation_type'] = 'declined';
          _playersWithConfirmations[index]['confirmed_at'] =
              DateTime.now().toIso8601String();
          _playersWithConfirmations[index]['confirmation_method'] = 'manual';
          _playersWithConfirmations[index]['notes'] = notes;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $playerName declinou presença'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao declinar presença'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _resetPlayerConfirmation(
      String playerId, String playerName) async {
    try {
      setState(() {
        _isSaving = true;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) return;

      // Verificar se o jogo ainda está ativo
      final isGameActive =
          await GameService.isGameActive(gameId: selectedGame.id);
      if (!isGameActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Jogo pausado ou inativado. Confirmação não permitida.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final confirmation =
          await PlayerConfirmationService.resetPlayerConfirmation(
        gameId: selectedGame.id,
        playerId: playerId,
      );

      if (confirmation != null) {
        // Atualizar lista local
        final index = _playersWithConfirmations.indexWhere(
          (p) => p['player_id'].toString() == playerId,
        );
        if (index != -1) {
          _playersWithConfirmations[index]['confirmation_type'] = 'pending';
          _playersWithConfirmations[index]['confirmed_at'] = null;
          _playersWithConfirmations[index]['confirmation_method'] = null;
          _playersWithConfirmations[index]['notes'] = null;
        }

        // Limpar nota
        _confirmationNotes[playerId] = '';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔄 Confirmação de $playerName resetada'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao resetar confirmação'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showNotesDialog(String playerId, String playerName) {
    final notesController = TextEditingController(
      text: _confirmationNotes[playerId] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Observações - $playerName',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Adicione observações sobre a confirmação...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.dividerLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _confirmationNotes[playerId] = notesController.text;
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Color _getConfirmationColor(String confirmationType) {
    switch (confirmationType) {
      case 'confirmed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getConfirmationIcon(String confirmationType) {
    switch (confirmationType) {
      case 'confirmed':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getConfirmationText(String confirmationType) {
    switch (confirmationType) {
      case 'confirmed':
        return 'Confirmado';
      case 'declined':
        return 'Declinado';
      case 'pending':
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Confirmação Manual',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadPlayersWithConfirmations,
              tooltip: 'Atualizar Lista',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildPlayersList(selectedGame),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.alert,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPlayersWithConfirmations,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList(selectedGame) {
    if (_playersWithConfirmations.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum Jogador',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Não há jogadores cadastrados neste jogo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calcular estatísticas
    final confirmedCount = _playersWithConfirmations
        .where((p) => p['confirmation_type'] == 'confirmed')
        .length;
    final declinedCount = _playersWithConfirmations
        .where((p) => p['confirmation_type'] == 'declined')
        .length;
    final pendingCount = _playersWithConfirmations
        .where((p) => p['confirmation_type'] == 'pending')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com estatísticas
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedGame?.organizationName ?? 'Jogo',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_playersWithConfirmations.length} jogadores',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Estatísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Confirmados',
                          confirmedCount,
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Pendentes',
                          pendingCount,
                          Colors.orange,
                          Icons.pending,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Declinados',
                          declinedCount,
                          Colors.red,
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de jogadores
          ..._playersWithConfirmations.map((player) {
            final playerId = player['player_id'].toString();
            final playerName =
                player['players']['name'] ?? 'Nome não informado';
            final playerType =
                player['game_players']['player_type'] ?? 'casual';
            final confirmationType = player['confirmation_type'] ?? 'pending';
            final confirmedAt = player['confirmed_at'];
            final notes = _confirmationNotes[playerId] ?? '';

            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do jogador
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            playerName.isNotEmpty
                                ? playerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: playerType == 'monthly'
                                          ? AppColors.primary.withOpacity(0.2)
                                          : AppColors.secondary
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      playerType == 'monthly'
                                          ? 'Mensal'
                                          : 'Avulso',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: playerType == 'monthly'
                                            ? AppColors.primary
                                            : AppColors.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _getConfirmationIcon(confirmationType),
                                    color:
                                        _getConfirmationColor(confirmationType),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getConfirmationText(confirmationType),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getConfirmationColor(
                                          confirmationType),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.note_add_outlined, size: 20),
                          onPressed: () =>
                              _showNotesDialog(playerId, playerName),
                          tooltip: 'Adicionar Observação',
                        ),
                      ],
                    ),

                    // Observações
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.dividerLight),
                        ),
                        child: Text(
                          notes,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],

                    // Data de confirmação
                    if (confirmedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Confirmado em: ${_formatDateTime(confirmedAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Botões de ação
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _confirmPlayer(playerId, playerName),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _declinePlayer(playerId, playerName),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Declinar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () => _resetPlayerConfirmation(
                                  playerId, playerName),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Resetar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
